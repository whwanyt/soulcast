import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';

import 'agent_chat_image_gallery.dart';

/// 图片生成片段的固定高度状态卡，覆盖生成中、失败与可预览图片。
class AgentChatImagePartBlock extends StatelessWidget {
  const AgentChatImagePartBlock({super.key, required this.part});

  static const _cardHeight = 280.0;

  final ChatImagePart part;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final translations = t.agent.generateImage;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.55);

    return SizedBox(
      width: double.infinity,
      height: _cardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: switch (part.status) {
            ChatImagePartStatus.generating => _GeneratingImageCard(
              theme: theme,
              colorScheme: colorScheme,
              label: translations.generating,
            ),
            ChatImagePartStatus.failed => _StatusPane(
              colorScheme: colorScheme,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  part.errorMessage?.trim().isNotEmpty == true
                      ? part.errorMessage!
                      : translations.requestFailedResult,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            ChatImagePartStatus.ready => _ReadyImage(url: part.url ?? ''),
          },
        ),
      ),
    );
  }
}

class _GeneratingImageCard extends StatelessWidget {
  const _GeneratingImageCard({
    required this.theme,
    required this.colorScheme,
    required this.label,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPane extends StatelessWidget {
  const _StatusPane({required this.colorScheme, required this.child});

  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(child: child),
    );
  }
}

class _ReadyImage extends StatelessWidget {
  const _ReadyImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = t.agent.generateImage;
    final localFile = resolveAppImageLocalFile(url);
    final errorBox = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            translations.imageLoadFailed,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );

    final image = localFile != null
        ? Image.file(
            localFile,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => errorBox,
          )
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, imageUrl) => placeholder,
            errorWidget: (context, imageUrl, error) => errorBox,
          );

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: url.trim().isEmpty
            ? null
            : () => AgentChatImagePreviewScope.openPreview(context, url),
        child: image,
      ),
    );
  }
}
