import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';

import 'agent_chat_bubble_style.dart';
import 'agent_chat_image_gallery.dart';
import 'agent_chat_message_tile.dart';

/// 支持流式内容跟随、位置保持和消息过滤的聊天消息列表。
class AgentChatMessageList extends ConsumerStatefulWidget {
  const AgentChatMessageList({
    super.key,
    required this.messages,
    this.isSending = false,
    this.onContinueReply,
    this.onRegenerate,
    this.onSelectAssistantVersion,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.isCharacterChat = false,
    this.bubbleFill,
  });

  final List<ChatConversationMessage> messages;
  final bool isSending;
  final VoidCallback? onContinueReply;
  final VoidCallback? onRegenerate;
  final ValueChanged<(String messageId, int index)>? onSelectAssistantVersion;
  final double topPadding;
  final double bottomPadding;

  /// 角色会话：隐藏助手「AI」标识，并可用头像主色半透明气泡底。
  final bool isCharacterChat;

  /// 角色会话：头像主色半透明气泡底；`null` 用默认主题色。
  final Color? bubbleFill;

  @override
  ConsumerState<AgentChatMessageList> createState() =>
      _AgentChatMessageListState();
}

class _AgentChatMessageListState extends ConsumerState<AgentChatMessageList> {
  late final FlutterListViewController _controller;
  bool _isFollowingBottom = true;
  bool _showScrollToBottom = false;
  int _forceInitialBottomIndex = 0;
  double _lastViewInsetBottom = 0;
  double? _lastViewportHeight;
  List<ChatConversationMessage> _visibleMessages = const [];
  bool _showToolMessages = true;

  @override
  void initState() {
    super.initState();
    _controller = FlutterListViewController();
    _scheduleJumpToBottom();
  }

  @override
  void didUpdateWidget(covariant AgentChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sendingChanged = oldWidget.isSending != widget.isSending;
    if (!_messagesChanged(oldWidget.messages, widget.messages) &&
        !sendingChanged) {
      return;
    }

    if (_isFollowingBottom) {
      _scheduleJumpToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetBottom = MediaQuery.viewInsetsOf(context).bottom;
    final showToolMessages = ref.watch(
      appPreferencesProvider.select((state) => state.showToolMessages),
    );
    final showMemoryMessages = ref.watch(
      appPreferencesProvider.select((state) => state.showMemoryMessages),
    );
    _showToolMessages = showToolMessages;
    final nextVisibleMessages = _filterVisibleMessages(
      messages: widget.messages,
      showMemoryMessages: showMemoryMessages,
    );
    if (_isFollowingBottom &&
        _messagesChanged(_visibleMessages, nextVisibleMessages)) {
      _scheduleJumpToBottom();
    }
    _visibleMessages = nextVisibleMessages;
    final imageUrls = collectConversationImageUrls(_visibleMessages);

    return AgentChatImagePreviewScope(
      imageUrls: imageUrls,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _handleViewportEnvironment(
            viewInsetBottom: viewInsetBottom,
            viewportHeight: constraints.maxHeight,
          );

          return AgentChatBubbleStyle(
            isCharacterChat: widget.isCharacterChat,
            bubbleFill: widget.bubbleFill,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: FlutterListView(
                      controller: _controller,
                      delegate: FlutterListViewDelegate(
                        _buildListItem,
                        childCount: _listItemCount,
                        onItemKey: _listItemKey,
                        keepPosition: true,
                        keepPositionOffset: 40,
                        preferItemHeight: 96,
                        initIndex: _lastListItemIndex,
                        initOffsetBasedOnBottom: true,
                        forceToExecuteInitIndex: _forceInitialBottomIndex,
                        firstItemAlign: FirstItemAlign.start,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _showScrollToBottom
                        ? Center(
                            child: FilledButton.icon(
                              key: const ValueKey('scroll_to_bottom'),
                              onPressed: _scrollToBottom,
                              style: FilledButton.styleFrom(
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(LucideIcons.arrowDown, size: 16),
                              label: Text(
                                context.t.chat.scrollToBottom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int get _listItemCount => _visibleMessages.length + 2;

  int get _lastListItemIndex => _listItemCount - 1;

  Widget? _buildListItem(BuildContext context, int index) {
    if (index == 0) {
      return SizedBox(height: widget.topPadding);
    }

    if (index == _lastListItemIndex) {
      return SizedBox(height: widget.bottomPadding);
    }

    final messageIndex = index - 1;
    if (messageIndex >= _visibleMessages.length) {
      return null;
    }

    final message = _visibleMessages[messageIndex];
    final isLastMessage = messageIndex == _visibleMessages.length - 1;
    final isTrailingAssistant = _isTrailingAssistant(messageIndex);
    final isActiveTurn =
        widget.isSending &&
        isTrailingAssistant &&
        message.role == ChatConversationRole.assistant;
    final showContinueReply =
        !widget.isSending &&
        isTrailingAssistant &&
        message.role == ChatConversationRole.assistant &&
        message.isInterrupted &&
        widget.onContinueReply != null;
    final showRegenerate =
        !widget.isSending &&
        isTrailingAssistant &&
        message.role == ChatConversationRole.assistant &&
        widget.onRegenerate != null;
    final showVersionSwitcher =
        !isActiveTurn &&
        message.role == ChatConversationRole.assistant &&
        message.hasMultipleVersions &&
        widget.onSelectAssistantVersion != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastMessage
            ? 0
            : message.role == ChatConversationRole.user
            ? 12
            : 2,
      ),
      child: AgentChatMessageTile(
        // 必须用稳定 id：流式更新时 fingerprint 会变，换 key 会丢掉高度缓存并触发闪烁。
        key: ValueKey(message.id),
        message: message,
        showToolMessages: _showToolMessages,
        isActiveTurn: isActiveTurn,
        showContinueReply: showContinueReply,
        onContinueReply: showContinueReply ? widget.onContinueReply : null,
        showRegenerate: showRegenerate,
        onRegenerate: showRegenerate ? widget.onRegenerate : null,
        onSelectPreviousVersion: showVersionSwitcher
            ? () {
                widget.onSelectAssistantVersion?.call((
                  message.id,
                  message.selectedVersionIndex - 1,
                ));
              }
            : null,
        onSelectNextVersion: showVersionSwitcher
            ? () {
                widget.onSelectAssistantVersion?.call((
                  message.id,
                  message.selectedVersionIndex + 1,
                ));
              }
            : null,
      ),
    );
  }

  String _listItemKey(int index) {
    if (index == 0) {
      return 'top_padding';
    }
    if (index == _lastListItemIndex) {
      return 'bottom_padding';
    }
    // FlutterListView 按 key 缓存 item 高度；流式内容变化时 key 必须稳定。
    return _visibleMessages[index - 1].id;
  }

  /// 忽略尾部 memory 后，当前项是否为会话末尾的助手消息。
  bool _isTrailingAssistant(int messageIndex) {
    for (var index = _visibleMessages.length - 1; index >= 0; index--) {
      final role = _visibleMessages[index].role;
      if (role == ChatConversationRole.memory) {
        continue;
      }
      return index == messageIndex && role == ChatConversationRole.assistant;
    }
    return false;
  }

  List<ChatConversationMessage> _filterVisibleMessages({
    required List<ChatConversationMessage> messages,
    required bool showMemoryMessages,
  }) {
    return [
      for (final message in messages)
        if (_shouldShowMessage(message, showMemoryMessages: showMemoryMessages))
          message,
    ];
  }

  bool _shouldShowMessage(
    ChatConversationMessage message, {
    required bool showMemoryMessages,
  }) {
    return switch (message.role) {
      ChatConversationRole.memory => showMemoryMessages,
      ChatConversationRole.user || ChatConversationRole.assistant => true,
    };
  }

  void _handleViewportEnvironment({
    required double viewInsetBottom,
    required double viewportHeight,
  }) {
    final didKeyboardOpen = viewInsetBottom > _lastViewInsetBottom;
    final lastViewportHeight = _lastViewportHeight;
    final didViewportShrink =
        lastViewportHeight != null && viewportHeight < lastViewportHeight;
    _lastViewInsetBottom = viewInsetBottom;
    _lastViewportHeight = viewportHeight;

    if (!didKeyboardOpen && !didViewportShrink) {
      return;
    }

    _isFollowingBottom = true;
    _showScrollToBottom = false;
    _forceInitialBottomIndex++;
    _scheduleJumpToBottom();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final isNearBottom = notification.metrics.extentAfter <= 48;
    final isUserScroll =
        notification is ScrollUpdateNotification &&
        notification.dragDetails != null;

    if (isUserScroll && !isNearBottom && _isFollowingBottom) {
      setState(() {
        _isFollowingBottom = false;
        _showScrollToBottom = true;
      });
      return false;
    }

    if (isNearBottom && (!_isFollowingBottom || _showScrollToBottom)) {
      _resumeFollowingBottom();
    }

    return false;
  }

  void _scrollToBottom() {
    _resumeFollowingBottom(forceInitialBottom: true);
    _scheduleAnimateToBottom();
  }

  void _resumeFollowingBottom({bool forceInitialBottom = false}) {
    if (_isFollowingBottom && !_showScrollToBottom && !forceInitialBottom) {
      return;
    }

    setState(() {
      _isFollowingBottom = true;
      _showScrollToBottom = false;
      if (forceInitialBottom) {
        _forceInitialBottomIndex++;
      }
    });
  }

  void _scheduleJumpToBottom() {
    if (widget.messages.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isFollowingBottom || _visibleMessages.isEmpty) {
        return;
      }
      _controller.sliverController.jumpToIndex(
        _lastListItemIndex,
        offsetBasedOnBottom: true,
      );
    });
  }

  void _scheduleAnimateToBottom() {
    if (_visibleMessages.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _visibleMessages.isEmpty) {
        return;
      }
      _controller.sliverController.animateToIndex(
        _lastListItemIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offsetBasedOnBottom: true,
      );
    });
  }

  bool _messagesChanged(
    List<ChatConversationMessage> oldMessages,
    List<ChatConversationMessage> newMessages,
  ) {
    if (oldMessages.length != newMessages.length) {
      return true;
    }
    if (oldMessages.isEmpty) {
      return false;
    }

    final oldLast = oldMessages.last;
    final newLast = newMessages.last;
    return oldLast.streamFingerprint != newLast.streamFingerprint;
  }
}
