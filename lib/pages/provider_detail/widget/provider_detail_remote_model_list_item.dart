part of 'provider_detail_widgets.dart';

/// 远端模型目录中的单个可导入模型。
class ProviderDetailRemoteModelListItem extends StatelessWidget {
  const ProviderDetailRemoteModelListItem({
    super.key,
    required this.model,
    required this.isAdded,
    required this.isAdding,
    required this.onAdd,
  });

  final RemoteAiModel model;
  final bool isAdded;
  final bool isAdding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = context.t.providerSettings;
    final canAdd = !isAdded && !isAdding;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        leading: Icon(LucideIcons.bot, color: colorScheme.onSurfaceVariant),
        title: Text(model.id, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          model.ownedBy ?? model.object,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: canAdd ? onAdd : null,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          icon: isAdding
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onSecondaryContainer,
                  ),
                )
              : Icon(isAdded ? LucideIcons.check : LucideIcons.plus, size: 14),
          label: Text(
            isAdded ? translations.modelAdded : translations.importModel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
