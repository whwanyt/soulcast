import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';

import 'agent_chat_image_gallery.dart';
import 'agent_chat_message_shared.dart';

/// 用户消息气泡。
class AgentUserChatMessageTile extends StatelessWidget {
  const AgentUserChatMessageTile({super.key, required this.message});

  final ChatConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = resolveAgentChatMessageConfig(
      context,
      _userMessageConfig(colorScheme, context.t),
    );
    final contentStyle =
        agentChatMessageContentStyle(theme, config) ??
        theme.textTheme.bodyLarge!.copyWith(color: config.contentColor);
    final mentionStyle = contentStyle.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    final attachments = [
      for (final part in message.parts)
        if (part is ChatAttachmentPart) part,
    ];
    final content = message.content.trim();

    return AgentChatMessageBubble(
      isUser: true,
      config: config,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attachments.isNotEmpty) ...[
            _UserAttachmentsBlock(attachments: attachments),
            if (content.isNotEmpty) const SizedBox(height: 8),
          ],
          if (content.isNotEmpty)
            Text.rich(
              TextSpan(
                children: _buildContentSpans(
                  message.content,
                  contentStyle: contentStyle,
                  mentionStyle: mentionStyle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserAttachmentsBlock extends StatelessWidget {
  const _UserAttachmentsBlock({required this.attachments});

  final List<ChatAttachmentPart> attachments;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final part in attachments)
          switch (part.kind) {
            ChatAttachmentKind.image => _UserAttachmentImage(part: part),
            ChatAttachmentKind.document => _UserAttachmentDocument(part: part),
          },
      ],
    );
  }
}

class _UserAttachmentImage extends StatelessWidget {
  const _UserAttachmentImage({required this.part});

  static const _size = 120.0;

  final ChatAttachmentPart part;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localFile = resolveAppImageLocalFile(part.localPath);

    return SizedBox(
      width: _size,
      height: _size,
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: part.localPath.trim().isEmpty
              ? null
              : () => AgentChatImagePreviewScope.openPreview(
                  context,
                  part.localPath,
                ),
          child: localFile == null
              ? Icon(LucideIcons.imageOff, color: colorScheme.onSurfaceVariant)
              : Image.file(
                  localFile,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      LucideIcons.imageOff,
                      color: colorScheme.onSurfaceVariant,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _UserAttachmentDocument extends StatelessWidget {
  const _UserAttachmentDocument({required this.part});

  final ChatAttachmentPart part;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220, minHeight: 40),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.fileText, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  part.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<InlineSpan> _buildContentSpans(
  String content, {
  required TextStyle contentStyle,
  required TextStyle mentionStyle,
}) {
  if (!ChatCreateImageMention.contains(content)) {
    return [TextSpan(text: content, style: contentStyle)];
  }

  final spans = <InlineSpan>[];
  var start = 0;
  for (final match in ChatCreateImageMention.pattern.allMatches(content)) {
    if (match.start > start) {
      spans.add(
        TextSpan(
          text: content.substring(start, match.start),
          style: contentStyle,
        ),
      );
    }
    spans.add(TextSpan(text: match.group(0)!, style: mentionStyle));
    start = match.end;
  }
  if (start < content.length) {
    spans.add(TextSpan(text: content.substring(start), style: contentStyle));
  }
  return spans;
}

AgentChatMessageTileConfig _userMessageConfig(
  ColorScheme colorScheme,
  Translations translations,
) {
  return AgentChatMessageTileConfig(
    label: translations.chat.role.me,
    icon: LucideIcons.userRound,
    backgroundColor: colorScheme.surfaceContainerHighest,
    contentColor: colorScheme.onSurface,
    labelColor: colorScheme.onSurfaceVariant,
  );
}
