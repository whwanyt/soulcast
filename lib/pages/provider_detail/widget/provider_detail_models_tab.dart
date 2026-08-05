part of 'provider_detail_widgets.dart';

/// 当前服务商的模型列表页签。
class ProviderDetailModelsTab extends StatelessWidget {
  const ProviderDetailModelsTab({
    super.key,
    required this.selectedProvider,
    required this.models,
    required this.onAddModel,
    required this.onFetchModels,
    required this.onModelEditing,
    required this.onModelDeleted,
    required this.onModelEnabledChanged,
  });

  final AiProviderEntity? selectedProvider;
  final AsyncValue<List<AiModelEntity>> models;
  final ValueChanged<AiProviderEntity> onAddModel;
  final void Function(AiProviderEntity provider, List<AiModelEntity> models)
  onFetchModels;
  final void Function(AiProviderEntity provider, {AiModelEntity? model})
  onModelEditing;
  final ValueChanged<AiModelEntity> onModelDeleted;
  final void Function({required String modelId, required bool isEnabled})
  onModelEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final provider = selectedProvider;
    if (provider == null) {
      return ProviderDetailProviderStatusView(
        icon: LucideIcons.bot,
        text: context.t.providerSettings.selectProviderFirst,
      );
    }

    return Column(
      children: [
        Expanded(
          child: models.when(
            data: (items) {
              if (items.isEmpty) {
                return ProviderDetailProviderStatusView(
                  icon: LucideIcons.box,
                  text: context.t.providerSettings.noModels,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemBuilder: (context, index) {
                  final model = items[index];
                  return ProviderDetailModelListItem(
                    model: model,
                    onEdit: () => onModelEditing(provider, model: model),
                    onDelete: () => onModelDeleted(model),
                    onEnabledChanged: (value) => onModelEnabledChanged(
                      modelId: model.id,
                      isEnabled: value,
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemCount: items.length,
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (error, stackTrace) => ProviderDetailProviderStatusView(
              icon: LucideIcons.circleAlert,
              text: error.toString(),
            ),
          ),
        ),
        models.maybeWhen(
          data: (items) {
            return ProviderDetailModelFooter(
              onAddModel: () => onAddModel(provider),
              onFetchModels: () => onFetchModels(provider, items),
            );
          },
          orElse: () => ProviderDetailModelFooter(
            onAddModel: () => onAddModel(provider),
            onFetchModels: null,
          ),
        ),
      ],
    );
  }
}
