part of '../file_library_page.dart';

class FileLibraryCard extends StatelessWidget {
  const FileLibraryCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final AgentLibraryItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadii.xs);

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.isImage)
              FileLibraryImageThumb(path: item.path)
            else ...[
              const FileLibraryFilePlaceholder(),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x99000000)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatByteSize(item.bytes),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 本地图片缩略图，含占位与错误态。
class FileLibraryImageThumb extends StatelessWidget {
  const FileLibraryImageThumb({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          LucideIcons.image,
          size: 36,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => placeholder,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return placeholder;
      },
    );
  }
}

/// 非图片文件的占位展示。
class FileLibraryFilePlaceholder extends StatelessWidget {
  const FileLibraryFilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          LucideIcons.file,
          size: 40,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 文件库为空时的引导卡片。
