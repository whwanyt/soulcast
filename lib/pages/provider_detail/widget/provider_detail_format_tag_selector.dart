part of 'provider_detail_widgets.dart';

/// 为模型选择输入或输出格式标签的多选控件。
class ProviderDetailFormatTagSelector extends StatelessWidget {
  const ProviderDetailFormatTagSelector({
    super.key,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in AiModelFormatTags.known)
              FilterChip(
                label: Text(
                  providerFormatTagLabel(context, tag),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selected.contains(tag),
                onSelected: (isSelected) {
                  final next = {...selected};
                  if (isSelected) {
                    next.add(tag);
                  } else {
                    next.remove(tag);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}
