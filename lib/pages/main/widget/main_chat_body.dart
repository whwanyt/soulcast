import 'package:flutter/material.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/widgets/agent_chat/agent_chat.dart';

import 'main_chat_empty_view.dart';

/// 普通会话列表顶部留白（避开顶栏按钮）。
const mainChatListTopPadding = 72.0;

/// 角色会话列表顶部留白（与顶部渐隐同高，位于 SafeArea 内）。
const mainChatCharacterListTopPadding = 160.0;

/// 普通会话列表底部留白（避开输入区）。
const mainChatListBottomPadding = 128.0;

/// 角色会话列表底部留白（与底部渐隐同高，位于 SafeArea 内）。
const mainChatCharacterListBottomPadding = 128.0;

/// 按会话类型解析列表底部留白。
double mainChatListBottomPaddingFor({required bool isCharacterChat}) {
  return isCharacterChat
      ? mainChatCharacterListBottomPadding
      : mainChatListBottomPadding;
}

/// 按会话类型解析列表顶部留白。
double mainChatListTopPaddingFor({required bool isCharacterChat}) {
  return isCharacterChat
      ? mainChatCharacterListTopPadding
      : mainChatListTopPadding;
}

/// 主聊天区：加载中、空态或消息列表。
class MainChatBody extends StatelessWidget {
  const MainChatBody({
    super.key,
    required this.isLoadingMessages,
    required this.hasMessages,
    required this.messages,
    required this.isSending,
    required this.onContinueReply,
    required this.onRegenerate,
    required this.onSelectAssistantVersion,
    this.isCharacterChat = false,
    this.bubbleFill,
    this.keyboardInset = 0,
  });

  final bool isLoadingMessages;
  final bool hasMessages;
  final List<ChatConversationMessage> messages;
  final bool isSending;
  final VoidCallback onContinueReply;
  final VoidCallback onRegenerate;
  final ValueChanged<(String messageId, int index)> onSelectAssistantVersion;
  final bool isCharacterChat;

  /// 角色会话气泡半透明底色（头像主色）。
  final Color? bubbleFill;

  /// 键盘高度；`resizeToAvoidBottomInset: false` 时用于加大列表底部留白。
  final double keyboardInset;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMessages) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (!hasMessages) {
      return const MainChatEmptyView();
    }

    return AgentChatMessageList(
      messages: messages,
      isSending: isSending,
      onContinueReply: onContinueReply,
      onRegenerate: onRegenerate,
      onSelectAssistantVersion: onSelectAssistantVersion,
      topPadding: mainChatListTopPaddingFor(isCharacterChat: isCharacterChat),
      bottomPadding:
          mainChatListBottomPaddingFor(isCharacterChat: isCharacterChat) +
          keyboardInset,
      isCharacterChat: isCharacterChat,
      bubbleFill: bubbleFill,
    );
  }
}
