part of '../character_edit_page.dart';

/// 新建角色页的 AI 辅助生成底部面板。
class CharacterEditAiAssistSheet extends ConsumerStatefulWidget {
  const CharacterEditAiAssistSheet({super.key});

  @override
  ConsumerState<CharacterEditAiAssistSheet> createState() =>
      _CharacterEditAiAssistSheetState();
}

class _CharacterEditAiAssistSheetState
    extends ConsumerState<CharacterEditAiAssistSheet> {
  final _ideaController = TextEditingController();
  bool _isGenerating = false;
  String? _selectedTextModelId;

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.characterEdit;
    final colorScheme = Theme.of(context).colorScheme;
    final modelsAsync = ref.watch(aiModelsProvider);
    final providersAsync = ref.watch(aiProvidersProvider);
    final textModels = _enabledTextModels(
      modelsAsync.whenOrNull(data: (items) => items) ?? const [],
    );
    final providers =
        providersAsync.whenOrNull(data: (items) => items) ?? const [];
    _ensureSelectedTextModel(textModels);

    final selectedModel = _findModel(textModels, _selectedTextModelId);
    final providerName = selectedModel == null
        ? null
        : _findProvider(providers, selectedModel.providerId)?.name;
    final modelLabel = selectedModel == null
        ? translations.modelHint
        : providerName == null
        ? selectedModel.name
        : '${selectedModel.name} · $providerName';

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.aiAssistTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _ideaController,
            enabled: !_isGenerating,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            labelText: translations.ideaLabel,
            hintText: translations.ideaHint,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isGenerating
                ? null
                : () => _showTextModelSelector(
                    textModels: textModels,
                    providers: providers,
                  ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.bot,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        translations.modelLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        modelLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_isGenerating) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isGenerating || textModels.isEmpty
                ? null
                : _generateWithAi,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: Icon(
              _isGenerating ? LucideIcons.loaderCircle : LucideIcons.sparkles,
            ),
            label: Text(
              _isGenerating ? translations.generating : translations.generate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _ensureSelectedTextModel(List<AiModelEntity> textModels) {
    if (textModels.isEmpty) {
      if (_selectedTextModelId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          setState(() => _selectedTextModelId = null);
        });
      }
      return;
    }

    final selectedStillValid = textModels.any(
      (model) => model.id == _selectedTextModelId,
    );
    if (selectedStillValid) {
      return;
    }

    final fallbackId = textModels.first.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _selectedTextModelId = fallbackId);
    });
  }

  Future<void> _showTextModelSelector({
    required List<AiModelEntity> textModels,
    required List<AiProviderEntity> providers,
  }) async {
    final translations = context.t.characterEdit;
    if (textModels.isEmpty) {
      SmartDialog.showToast(translations.noTextModel);
      return;
    }

    final providerMap = {
      for (final provider in providers) provider.id: provider,
    };

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      translations.modelLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: context.t.main.modelSelector.manage,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      const ProviderSettingsRoute().push(context);
                    },
                    icon: const Icon(LucideIcons.settings),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: textModels.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final model = textModels[index];
                    final provider = providerMap[model.providerId];
                    final isSelected = model.id == _selectedTextModelId;
                    return CharacterEditModelSelectorItem(
                      model: model,
                      providerName:
                          provider?.name ??
                          context.t.main.modelSelector.unknown,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedTextModelId = model.id);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateWithAi() async {
    final translations = context.t.characterEdit;
    final idea = _ideaController.text.trim();
    if (idea.isEmpty) {
      SmartDialog.showToast(translations.ideaRequired);
      return;
    }

    final modelId = _selectedTextModelId;
    if (modelId == null) {
      SmartDialog.showToast(translations.noTextModel);
      return;
    }

    var shouldResetGenerating = true;
    setState(() => _isGenerating = true);
    try {
      final preferences = ref.read(appPreferencesProvider);
      final translationsRoot = context.t;
      final draft = await ref
          .read(generateCharacterServiceProvider)
          .generate(
            idea: idea,
            textModelId: modelId,
            systemTemplate: effectivePromptTemplate(
              id: PromptId.generateCharacterSystem,
              customPrompts: preferences.customPrompts,
              t: translationsRoot,
            ),
            userTemplate: effectivePromptTemplate(
              id: PromptId.generateCharacterUser,
              customPrompts: preferences.customPrompts,
              t: translationsRoot,
            ),
            systemFallbackTemplate: defaultPromptTemplate(
              translationsRoot,
              PromptId.generateCharacterSystem,
            ),
            userFallbackTemplate: defaultPromptTemplate(
              translationsRoot,
              PromptId.generateCharacterUser,
            ),
          );
      if (!mounted) {
        return;
      }
      if (draft == null) {
        SmartDialog.showToast(translations.generateFailed);
        return;
      }
      shouldResetGenerating = false;
      Navigator.of(context).pop(draft);
    } finally {
      if (shouldResetGenerating && mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}

/// 角色编辑页文本模型选择列表项。
class CharacterEditModelSelectorItem extends StatelessWidget {
  const CharacterEditModelSelectorItem({
    required this.model,
    required this.providerName,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final AiModelEntity model;
  final String providerName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.surface
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Icon(
                      isSelected ? LucideIcons.check : LucideIcons.bot,
                      size: 18,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$providerName · ${model.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
