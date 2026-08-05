import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/speech/speech.dart';
import 'package:soulcast/i18n/strings.g.dart';

import 'package:soulcast/features/agent_tools/agent_tools.dart';

import 'agent_chat_image_part_block.dart';
import 'agent_chat_bubble_style.dart';
import 'agent_chat_message_shared.dart';
import 'agent_chat_tool_call_part_block.dart';

/// 助手消息气泡，按 parts 顺序展示推理、正文、图片与工具状态。
class AgentAssistantChatMessageTile extends StatelessWidget {
  const AgentAssistantChatMessageTile({
    super.key,
    required this.message,
    this.showToolMessages = true,
    this.isActiveTurn = false,
    this.showContinueReply = false,
    this.onContinueReply,
    this.showRegenerate = false,
    this.onRegenerate,
    this.onSelectPreviousVersion,
    this.onSelectNextVersion,
  });

  final ChatConversationMessage message;
  final bool showToolMessages;
  final bool isActiveTurn;
  final bool showContinueReply;
  final VoidCallback? onContinueReply;
  final bool showRegenerate;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSelectPreviousVersion;
  final VoidCallback? onSelectNextVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;
    final config = resolveAgentChatMessageConfig(
      context,
      _assistantMessageConfig(theme.colorScheme, t),
    );
    final bodyText = _assistantBodyText(message);
    final parts = [
      for (final part in message.parts)
        if (_shouldShowAssistantPart(part, showToolMessages: showToolMessages))
          part,
    ];
    final lastReasoningIndex = parts.lastIndexWhere(
      (part) => part is ChatReasoningPart,
    );
    final showVersionSwitcher =
        message.hasMultipleVersions &&
        onSelectPreviousVersion != null &&
        onSelectNextVersion != null;
    final showActions =
        showContinueReply ||
        showRegenerate ||
        showVersionSwitcher ||
        bodyText.isNotEmpty;
    final showRoleLabel = !AgentChatBubbleStyle.isCharacterChatOf(context);

    return AgentChatMessageBubble(
      isUser: false,
      config: config,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showRoleLabel) AgentChatMessageRoleLabel(config: config),
          if (showRoleLabel && parts.isNotEmpty) const SizedBox(height: 6),
          for (var index = 0; index < parts.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            _AssistantPartView(
              part: parts[index],
              config: config,
              isReasoningActive:
                  isActiveTurn &&
                  index == lastReasoningIndex &&
                  parts[index] is ChatReasoningPart,
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 8),
            _AssistantMessageActions(
              messageId: message.id,
              bodyText: bodyText,
              actionColor: AgentChatBubbleStyle.bubbleFillOf(context) != null
                  ? config.contentColor
                  : theme.colorScheme.primary,
              showContinueReply: showContinueReply && onContinueReply != null,
              onContinueReply: onContinueReply,
              showVersionSwitcher: showVersionSwitcher,
              versionLabel: t.chat.versionIndex(
                current: message.selectedVersionIndex + 1,
                total: message.versionCount,
              ),
              previousVersionLabel: t.chat.versionPrevious,
              nextVersionLabel: t.chat.versionNext,
              onSelectPreviousVersion: onSelectPreviousVersion,
              onSelectNextVersion: onSelectNextVersion,
              canSelectPrevious: message.selectedVersionIndex > 0,
              canSelectNext:
                  message.selectedVersionIndex < message.versionCount - 1,
              showRegenerate: showRegenerate && onRegenerate != null,
              regenerateTooltip: t.chat.regenerate,
              onRegenerate: onRegenerate,
            ),
          ],
        ],
      ),
    );
  }
}

String _assistantBodyText(ChatConversationMessage message) {
  final texts = [
    for (final part in message.parts)
      if (part is ChatTextPart && part.content.trim().isNotEmpty) part.content,
  ];
  if (texts.isNotEmpty) {
    return texts.join('\n\n').trim();
  }
  return message.content.trim();
}

class _AssistantMessageActions extends StatelessWidget {
  const _AssistantMessageActions({
    required this.messageId,
    required this.bodyText,
    required this.actionColor,
    required this.showContinueReply,
    required this.onContinueReply,
    required this.showVersionSwitcher,
    required this.versionLabel,
    required this.previousVersionLabel,
    required this.nextVersionLabel,
    required this.onSelectPreviousVersion,
    required this.onSelectNextVersion,
    required this.canSelectPrevious,
    required this.canSelectNext,
    required this.showRegenerate,
    required this.regenerateTooltip,
    required this.onRegenerate,
  });

  final String messageId;
  final String bodyText;
  final Color actionColor;
  final bool showContinueReply;
  final VoidCallback? onContinueReply;
  final bool showVersionSwitcher;
  final String versionLabel;
  final String previousVersionLabel;
  final String nextVersionLabel;
  final VoidCallback? onSelectPreviousVersion;
  final VoidCallback? onSelectNextVersion;
  final bool canSelectPrevious;
  final bool canSelectNext;
  final bool showRegenerate;
  final String regenerateTooltip;
  final VoidCallback? onRegenerate;

  Future<void> _confirmRegenerate(BuildContext context) async {
    final onRegenerate = this.onRegenerate;
    if (onRegenerate == null) {
      return;
    }

    final t = context.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            t.chat.regenerateConfirmTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(t.chat.regenerateConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                t.common.cancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                t.chat.regenerateConfirm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      onRegenerate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;
    final trimmedBody = bodyText.trim();
    final canCopy = trimmedBody.isNotEmpty;

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayMessageSpeechButton(
              messageId: messageId,
              text: bodyText,
              color: actionColor,
            ),
            _CompactActionIconButton(
              onPressed: canCopy
                  ? () => agentChatCopyTextToClipboard(context, trimmedBody)
                  : null,
              tooltip: t.chat.copy,
              icon: LucideIcons.copy,
              color: actionColor,
            ),
            if (showVersionSwitcher) ...[
              const SizedBox(width: 10),
              _CompactActionIconButton(
                onPressed: canSelectPrevious ? onSelectPreviousVersion : null,
                tooltip: previousVersionLabel,
                icon: LucideIcons.chevronLeft,
                color: actionColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  versionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: actionColor,
                  ),
                ),
              ),
              _CompactActionIconButton(
                onPressed: canSelectNext ? onSelectNextVersion : null,
                tooltip: nextVersionLabel,
                icon: LucideIcons.chevronRight,
                color: actionColor,
              ),
              const SizedBox(width: 10),
            ] else
              const SizedBox(width: 10),
            if (showRegenerate)
              _CompactActionIconButton(
                onPressed: () => _confirmRegenerate(context),
                tooltip: regenerateTooltip,
                icon: LucideIcons.refreshCw,
                color: actionColor,
              ),
          ],
        ),
        if (showContinueReply)
          TextButton(
            onPressed: onContinueReply,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: actionColor,
            ),
            child: Text(
              t.chat.continueReply,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _CompactActionIconButton extends StatelessWidget {
  const _CompactActionIconButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    this.color,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.all(4),
        minimumSize: const Size(36, 36),
        maximumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _AssistantPartView extends StatelessWidget {
  const _AssistantPartView({
    required this.part,
    required this.config,
    required this.isReasoningActive,
  });

  final ChatMessagePart part;
  final AgentChatMessageTileConfig config;
  final bool isReasoningActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (part) {
      ChatReasoningPart(:final content) => AgentChatMessageReasoningBlock(
        content: content,
        style: agentChatMessageReasoningStyle(theme, config),
        isActive: isReasoningActive,
      ),
      ChatTextPart(:final content) => AgentChatMessageThemedMarkdown(
        data: content,
        style: agentChatMessageContentStyle(theme, config),
        textScaler: MediaQuery.textScalerOf(context),
      ),
      final ChatImagePart imagePart => AgentChatImagePartBlock(part: imagePart),
      final ChatToolCallPart toolPart => AgentChatToolCallPartBlock(
        part: toolPart,
      ),
      ChatAttachmentPart() => const SizedBox.shrink(),
    };
  }
}

bool _shouldShowAssistantPart(
  ChatMessagePart part, {
  required bool showToolMessages,
}) {
  if (part is ChatAttachmentPart) {
    return false;
  }
  if (part is ChatToolCallPart) {
    // 生图以 ChatImagePart 为主展示，隐藏工程师向的工具 JSON。
    if (part.toolName == AgentToolIds.generateImage) {
      return false;
    }
    return showToolMessages;
  }
  return true;
}

AgentChatMessageTileConfig _assistantMessageConfig(
  ColorScheme colorScheme,
  Translations translations,
) {
  return AgentChatMessageTileConfig(
    label: translations.chat.role.assistant,
    icon: LucideIcons.sparkles,
    backgroundColor: agentChatAssistantMessageBackground,
    contentColor: colorScheme.onSurface,
    labelColor: colorScheme.onSurfaceVariant,
  );
}
