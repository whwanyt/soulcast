part of 'agent_chat_markdown.dart';

/// 支持本地文件与网络资源的 Markdown 图片。
class _AgentChatMarkdownImage extends StatelessWidget {
  const _AgentChatMarkdownImage({
    required this.url,
    required this.width,
    required this.height,
    required this.chrome,
  });

  static const _maxHeight = 220.0;

  final String url;
  final double? width;
  final double? height;
  final AgentChatMarkdownChrome chrome;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = t.agent.generateImage;
    final displayHeight = height == null || height! > _maxHeight
        ? _maxHeight
        : height!;
    final statusBox = SizedBox(
      width: displayHeight,
      height: displayHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: chrome.surface),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              translations.imageLoadFailed,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
    final placeholder = SizedBox(
      width: displayHeight,
      height: displayHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: chrome.surface),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );

    final localFile = resolveAppImageLocalFile(url);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = width ?? constraints.maxWidth;
          final image = localFile != null
              ? Image.file(
                  localFile,
                  height: displayHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => statusBox,
                )
              : CachedNetworkImage(
                  imageUrl: url,
                  height: displayHeight,
                  fit: BoxFit.contain,
                  placeholder: (context, imageUrl) => placeholder,
                  errorWidget: (context, imageUrl, error) => statusBox,
                );

          return Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: displayHeight,
                maxWidth: maxWidth,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: url.trim().isEmpty
                      ? null
                      : () => AgentChatImagePreviewScope.openPreview(
                          context,
                          url,
                        ),
                  borderRadius: chrome.radius,
                  child: Ink(
                    decoration: chrome.panel(),
                    child: ClipRRect(borderRadius: chrome.radius, child: image),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
