import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

import '../model/agent_library_item.dart';
import '../provider/agent_file_library_provider.dart';

/// 打开文件库选图底部面板，返回所选图片的本地绝对路径；取消则为 `null`。
Future<String?> showFileLibraryImagePicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return const FileLibraryImagePickerSheet();
    },
  );
}

/// 从 Agent 文件库中选择一张图片的底部面板。
class FileLibraryImagePickerSheet extends ConsumerWidget {
  const FileLibraryImagePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.fileLibrary;
    final itemsAsync = ref.watch(agentFileLibraryProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    translations.pickTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: translations.refresh,
                  onPressed: () =>
                      ref.read(agentFileLibraryProvider.notifier).refresh(),
                  icon: const Icon(LucideIcons.refreshCw, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: itemsAsync.when(
                data: (items) {
                  final images = [
                    for (final item in items)
                      if (item.isImage) item,
                  ];
                  if (images.isEmpty) {
                    return const _FileLibraryImagePickerEmpty();
                  }
                  return _FileLibraryImagePickerGrid(images: images);
                },
                loading: () => const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      translations.loadFailed(error: error.toString()),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileLibraryImagePickerGrid extends StatelessWidget {
  const _FileLibraryImagePickerGrid({required this.images});

  final List<AgentLibraryItem> images;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final item = images[index];
        return _FileLibraryImagePickerTile(
          path: item.path,
          onTap: () => Navigator.of(context).pop(item.path),
        );
      },
    );
  }
}

class _FileLibraryImagePickerTile extends StatelessWidget {
  const _FileLibraryImagePickerTile({required this.path, required this.onTap});

  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadii.xs);

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: _FileLibraryImagePickerThumb(path: path),
      ),
    );
  }
}

class _FileLibraryImagePickerThumb extends StatelessWidget {
  const _FileLibraryImagePickerThumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          LucideIcons.image,
          size: 28,
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

class _FileLibraryImagePickerEmpty extends StatelessWidget {
  const _FileLibraryImagePickerEmpty();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = context.t.fileLibrary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.imageOff,
              size: 36,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              translations.pickEmptyTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              translations.pickEmptyDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
