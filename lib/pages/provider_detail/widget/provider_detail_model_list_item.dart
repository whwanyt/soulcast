part of 'provider_detail_widgets.dart';

/// 单个本地模型配置及启用、编辑、删除动作。
class ProviderDetailModelListItem extends StatelessWidget {
  const ProviderDetailModelListItem({
    super.key,
    required this.model,
    required this.onEdit,
    required this.onDelete,
    required this.onEnabledChanged,
  });

  final AiModelEntity model;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatSummary = _formatTagsSummary(context, model);

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: formatSummary == null ? 72 : 88,
        child: ListTile(
          leading: Switch(value: model.isEnabled, onChanged: onEnabledChanged),
          title: Text(model.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            formatSummary == null
                ? model.model
                : '${model.model} · $formatSummary',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: context.t.common.edit,
                onPressed: onEdit,
                icon: const Icon(LucideIcons.pencil),
              ),
              IconButton(
                tooltip: context.t.common.delete,
                onPressed: onDelete,
                icon: const Icon(LucideIcons.trash2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _formatTagsSummary(BuildContext context, AiModelEntity model) {
    final translations = context.t.providerSettings;
    final parts = <String>[];
    if (model.inputFormats.isNotEmpty) {
      parts.add(
        '${translations.inputFormats}: '
        '${model.inputFormats.map((tag) => providerFormatTagLabel(context, tag)).join('/')}',
      );
    }
    if (model.outputFormats.isNotEmpty) {
      parts.add(
        '${translations.outputFormats}: '
        '${model.outputFormats.map((tag) => providerFormatTagLabel(context, tag)).join('/')}',
      );
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' · ');
  }
}

/// 将模型格式标签转换为本地化名称。
String providerFormatTagLabel(BuildContext context, String tag) {
  final formatTag = context.t.providerSettings.formatTag;
  return switch (tag) {
    AiModelFormatTags.text => formatTag.text,
    AiModelFormatTags.image => formatTag.image,
    _ => tag,
  };
}
