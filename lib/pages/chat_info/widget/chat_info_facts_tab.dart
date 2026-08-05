part of '../chat_info_page.dart';

/// 会话长期记忆事实列表页签。
class _FactsTab extends StatelessWidget {
  const _FactsTab({
    required this.facts,
    required this.isEnabled,
    required this.onFactAdded,
    required this.onFactEdited,
    required this.onFactDeleted,
  });

  final List<_FactDraft> facts;
  final bool isEnabled;
  final VoidCallback onFactAdded;
  final ValueChanged<int> onFactEdited;
  final ValueChanged<int> onFactDeleted;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.main.info;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                translations.memoriesTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: translations.addMemory,
              onPressed: isEnabled ? onFactAdded : null,
              icon: const Icon(LucideIcons.plus),
            ),
          ],
        ),
        if (facts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              translations.noMemories,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (var index = 0; index < facts.length; index++) ...[
            _FactListItem(
              key: ValueKey(facts[index].id),
              draft: facts[index],
              isEnabled: isEnabled,
              onTap: () => onFactEdited(index),
              onDeleted: () => onFactDeleted(index),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _FactListItem extends StatelessWidget {
  const _FactListItem({
    super.key,
    required this.draft,
    required this.isEnabled,
    required this.onTap,
    required this.onDeleted,
  });

  final _FactDraft draft;
  final bool isEnabled;
  final VoidCallback onTap;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryLabel(context, draft.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      draft.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: context.t.main.info.deleteMemory,
                onPressed: isEnabled ? onDeleted : null,
                icon: const Icon(LucideIcons.trash2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
