part of 'provider_detail_widgets.dart';

/// 拉取、筛选并导入远端模型目录的底部面板。
class ProviderDetailRemoteModelsSheet extends StatefulWidget {
  const ProviderDetailRemoteModelsSheet({
    super.key,
    required this.existingModelIds,
    required this.onFetchModels,
    required this.onModelAdded,
  });

  final Set<String> existingModelIds;
  final Future<List<RemoteAiModel>> Function() onFetchModels;
  final Future<bool> Function(RemoteAiModel model) onModelAdded;

  @override
  State<ProviderDetailRemoteModelsSheet> createState() =>
      _ProviderDetailRemoteModelsSheetState();
}

class _ProviderDetailRemoteModelsSheetState
    extends State<ProviderDetailRemoteModelsSheet> {
  late Future<List<RemoteAiModel>> _modelsFuture;
  late final Set<String> _addedModelIds;
  final Set<String> _addingModelIds = {};
  late final TextEditingController _filterController;

  @override
  void initState() {
    super.initState();
    _addedModelIds = {...widget.existingModelIds};
    _filterController = TextEditingController();
    _modelsFuture = widget.onFetchModels();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.providerSettings;
    final hasFilter = _filterController.text.trim().isNotEmpty;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    translations.fetchModelsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: translations.refreshModels,
                  onPressed: _refresh,
                  icon: const Icon(LucideIcons.refreshCw),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _filterController,
              hintText: translations.filterRemoteModelsHint,
              prefixIcon: const Icon(LucideIcons.search),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              suffixIcon: hasFilter
                  ? IconButton(
                      tooltip: context.t.common.clear,
                      onPressed: () {
                        _filterController.clear();
                        setState(() {});
                      },
                      icon: const Icon(LucideIcons.x),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<RemoteAiModel>>(
                future: _modelsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  final error = snapshot.error;
                  if (error != null) {
                    return ProviderDetailProviderStatusView(
                      icon: LucideIcons.circleAlert,
                      text: translations.fetchModelsFailed(
                        error: error.toString(),
                      ),
                    );
                  }

                  final models = snapshot.data ?? const <RemoteAiModel>[];
                  if (models.isEmpty) {
                    return ProviderDetailProviderStatusView(
                      icon: LucideIcons.box,
                      text: translations.noRemoteModels,
                    );
                  }

                  final filtered = _filterModels(models);
                  if (filtered.isEmpty) {
                    return ProviderDetailProviderStatusView(
                      icon: LucideIcons.search,
                      text: translations.noRemoteModelsMatch,
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final model = filtered[index];
                      final isAdded = _addedModelIds.contains(model.id);
                      final isAdding = _addingModelIds.contains(model.id);
                      return ProviderDetailRemoteModelListItem(
                        model: model,
                        isAdded: isAdded,
                        isAdding: isAdding,
                        onAdd: () => _addModel(model),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemCount: filtered.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<RemoteAiModel> _filterModels(List<RemoteAiModel> models) {
    final query = _filterController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return models;
    }
    return models
        .where((model) {
          final id = model.id.toLowerCase();
          final ownedBy = model.ownedBy?.toLowerCase() ?? '';
          final object = model.object.toLowerCase();
          return id.contains(query) ||
              ownedBy.contains(query) ||
              object.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _addModel(RemoteAiModel model) async {
    if (_addedModelIds.contains(model.id) ||
        _addingModelIds.contains(model.id)) {
      return;
    }

    setState(() => _addingModelIds.add(model.id));
    try {
      final added = await widget.onModelAdded(model);
      if (!mounted) {
        return;
      }
      if (added) {
        setState(() => _addedModelIds.add(model.id));
      }
    } finally {
      if (mounted) {
        setState(() => _addingModelIds.remove(model.id));
      }
    }
  }

  void _refresh() {
    setState(() => _modelsFuture = widget.onFetchModels());
  }
}
