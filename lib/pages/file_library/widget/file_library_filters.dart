part of '../file_library_page.dart';

List<AgentLibraryItem> _filterItems(
  List<AgentLibraryItem> items,
  FileLibraryFilter filter,
  String query,
) {
  Iterable<AgentLibraryItem> result = items;
  result = switch (filter) {
    FileLibraryFilter.all => result,
    FileLibraryFilter.images => result.where((item) => item.isImage),
    FileLibraryFilter.files => result.where((item) => !item.isImage),
  };

  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isNotEmpty) {
    result = result.where(
      (item) => item.name.toLowerCase().contains(normalizedQuery),
    );
  }

  return result.toList();
}

/// 文件库筛选栏。
class FileLibraryFilterBar extends StatelessWidget {
  const FileLibraryFilterBar({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final FileLibraryFilter selectedFilter;
  final ValueChanged<FileLibraryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final filter in FileLibraryFilter.values) ...[
          FileLibraryFilterChip(
            filter: filter,
            isSelected: filter == selectedFilter,
            onSelected: onSelected,
          ),
          if (filter != FileLibraryFilter.values.last)
            const SizedBox(width: 12),
        ],
      ],
    );
  }
}

/// 单个文件库筛选条件按钮。
class FileLibraryFilterChip extends StatelessWidget {
  const FileLibraryFilterChip({
    required this.filter,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final FileLibraryFilter filter;
  final bool isSelected;
  final ValueChanged<FileLibraryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? colorScheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: () => onSelected(filter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: isSelected
                  ? AppShadows.soft(colorScheme.shadow)
                  : const [],
            ),
            child: Center(
              child: Text(
                filter.label(context.t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 文件库网格卡片：图片仅展示缩略图，其它文件展示图标与元信息。
