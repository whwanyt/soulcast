import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';

/// 输入区上方的草稿附件预览条。
class MainChatDraftAttachmentsBar extends StatelessWidget {
  const MainChatDraftAttachmentsBar({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  final List<ChatAttachmentPart> attachments;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final part = attachments[index];
          return switch (part.kind) {
            ChatAttachmentKind.image => _DraftImageChip(
              part: part,
              onRemove: () => onRemove(part.id),
            ),
            ChatAttachmentKind.document => _DraftDocumentChip(
              part: part,
              onRemove: () => onRemove(part.id),
            ),
          };
        },
      ),
    );
  }
}

class _DraftImageChip extends StatelessWidget {
  const _DraftImageChip({required this.part, required this.onRemove});

  final ChatAttachmentPart part;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localFile = resolveAppImageLocalFile(part.localPath);

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: localFile == null
                    ? Icon(
                        LucideIcons.imageOff,
                        color: colorScheme.onSurfaceVariant,
                      )
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
          ),
          Positioned(
            top: 2,
            right: 2,
            child: _RemoveBadge(onPressed: onRemove),
          ),
        ],
      ),
    );
  }
}

class _DraftDocumentChip extends StatelessWidget {
  const _DraftDocumentChip({required this.part, required this.onRemove});

  final ChatAttachmentPart part;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SizedBox(
      width: 148,
      height: 72,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 28, 10),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        part.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: _RemoveBadge(onPressed: onRemove),
          ),
        ],
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: context.t.main.input.attach.remove,
      child: Material(
        color: colorScheme.scrim.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 22,
            height: 22,
            child: Icon(LucideIcons.x, size: 14, color: colorScheme.onPrimary),
          ),
        ),
      ),
    );
  }
}
