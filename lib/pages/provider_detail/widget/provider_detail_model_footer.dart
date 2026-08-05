part of 'provider_detail_widgets.dart';

/// 模型列表底部的新建与远端拉取操作栏。
class ProviderDetailModelFooter extends StatelessWidget {
  const ProviderDetailModelFooter({
    super.key,
    required this.onAddModel,
    required this.onFetchModels,
  });

  final VoidCallback onAddModel;
  final VoidCallback? onFetchModels;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.providerSettings;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withAlpha(160)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onAddModel,
                    icon: const Icon(LucideIcons.plus),
                    label: Text(
                      translations.addModel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.tonalIcon(
                    onPressed: onFetchModels,
                    icon: const Icon(LucideIcons.cloudDownload),
                    label: Text(
                      translations.fetchModels,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
