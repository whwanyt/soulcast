import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soulcast/features/browse_file_library/browse_file_library.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/utils/directory_usage.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';

import 'provider/file_library_filter_provider.dart';

part 'widget/file_library_filters.dart';
part 'widget/file_library_card.dart';
part 'widget/file_library_states.dart';
part 'widget/file_library_search_bar.dart';

/// Agent 目录文件库：浏览图片与普通文件。
class FileLibraryPage extends ConsumerStatefulWidget {
  const FileLibraryPage({super.key});

  @override
  ConsumerState<FileLibraryPage> createState() => _FileLibraryPageState();
}

class _FileLibraryPageState extends ConsumerState<FileLibraryPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedFilter = ref.watch(fileLibraryFilterControllerProvider);
    final itemsAsync = ref.watch(agentFileLibraryProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        title: Text(
          context.t.fileLibrary.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: context.t.fileLibrary.refresh,
            onPressed: () =>
                ref.read(agentFileLibraryProvider.notifier).refresh(),
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: FileLibraryFilterBar(
                      selectedFilter: selectedFilter,
                      onSelected: ref
                          .read(fileLibraryFilterControllerProvider.notifier)
                          .select,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ..._buildContentSlivers(context, itemsAsync, selectedFilter),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 96 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 36,
            right: 36,
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            child: FileLibrarySearchBar(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    AsyncValue<List<AgentLibraryItem>> itemsAsync,
    FileLibraryFilter filter,
  ) {
    return [
      itemsAsync.when(
        data: (items) {
          final visible = _filterItems(items, filter, _searchQuery);
          if (visible.isEmpty) {
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              sliver: const SliverToBoxAdapter(child: FileLibraryEmptyCard()),
            );
          }

          final imageUrls = [
            for (final item in items)
              if (item.isImage) item.path,
          ];

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = visible[index];
                return FileLibraryCard(
                  item: item,
                  onTap: () => _onItemTap(item, imageUrls),
                  onLongPress: () => _confirmDelete(item),
                );
              }, childCount: visible.length),
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, stackTrace) => SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.t.fileLibrary.loadFailed(error: error.toString()),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _onItemTap(AgentLibraryItem item, List<String> imageUrls) async {
    if (item.isImage) {
      final index = imageUrls.indexOf(item.path);
      await showAppImagePreview(
        context,
        urls: imageUrls,
        initialIndex: index < 0 ? 0 : index,
      );
      return;
    }

    await SharePlus.instance.share(ShareParams(files: [XFile(item.path)]));
  }

  Future<void> _confirmDelete(AgentLibraryItem item) async {
    final translations = context.t.fileLibrary;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            translations.deleteTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(translations.deleteMessage(name: item.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                context.t.common.cancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                context.t.common.delete,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref.read(agentFileLibraryProvider.notifier).deleteItem(item);
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(translations.deleted);
    } catch (error) {
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(translations.deleteFailed(error: error.toString()));
    }
  }
}
