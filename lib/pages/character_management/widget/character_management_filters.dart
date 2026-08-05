part of '../character_management_page.dart';

List<CharacterEntity> _filterCharacters(
  List<CharacterEntity> characters,
  CharacterManagementFilter filter,
  String query,
) {
  Iterable<CharacterEntity> result = characters;
  if (filter == CharacterManagementFilter.favorites) {
    result = result.where((character) => character.isFavorite);
  }

  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isNotEmpty) {
    result = result.where((character) {
      return character.name.toLowerCase().contains(normalizedQuery) ||
          character.description.toLowerCase().contains(normalizedQuery);
    });
  }

  final list = result.toList();
  if (filter == CharacterManagementFilter.recent) {
    list.sort((first, second) => second.lastUsedAt.compareTo(first.lastUsedAt));
  }
  return list;
}

enum _CharacterMenuAction { chat, edit, toggleFavorite, delete }

/// 角色收藏状态筛选栏。
class CharacterManagementFilterBar extends StatelessWidget {
  const CharacterManagementFilterBar({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final CharacterManagementFilter selectedFilter;
  final ValueChanged<CharacterManagementFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final filter in CharacterManagementFilter.values) ...[
          CharacterManagementFilterChip(
            filter: filter,
            isSelected: filter == selectedFilter,
            onSelected: onSelected,
          ),
          if (filter != CharacterManagementFilter.values.last)
            const SizedBox(width: 12),
        ],
      ],
    );
  }
}

/// 单个角色筛选条件按钮。
class CharacterManagementFilterChip extends StatelessWidget {
  const CharacterManagementFilterChip({
    required this.filter,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final CharacterManagementFilter filter;
  final bool isSelected;
  final ValueChanged<CharacterManagementFilter> onSelected;

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

/// 以头像铺满背景、底部仅展示名称的角色卡片。
