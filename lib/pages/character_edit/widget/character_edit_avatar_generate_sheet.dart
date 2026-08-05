part of '../character_edit_page.dart';

/// AI 生成头像底部面板：图像模型、画面比例与可编辑提示词。
class CharacterEditAvatarGenerateSheet extends ConsumerStatefulWidget {
  const CharacterEditAvatarGenerateSheet({
    required this.initialPrompt,
    required this.initialImageModelId,
    super.key,
  });

  final String initialPrompt;
  final String? initialImageModelId;

  @override
  ConsumerState<CharacterEditAvatarGenerateSheet> createState() =>
      _CharacterEditAvatarGenerateSheetState();
}

/// 头像生成画面比例，映射为 Images API `size`。
enum _AvatarAspectRatio {
  /// 竖屏 9:16（常称竖屏 16:9）。
  ratio16x9('1024x1792'),
  ratio4x3('1280x960'),
  ratio1x1('1024x1024');

  const _AvatarAspectRatio(this.apiSize);

  final String apiSize;
}

class _CharacterEditAvatarGenerateSheetState
    extends ConsumerState<CharacterEditAvatarGenerateSheet> {
  late final TextEditingController _promptController;
  bool _isGenerating = false;
  String? _selectedImageModelId;
  _AvatarAspectRatio _aspectRatio = _AvatarAspectRatio.ratio1x1;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt);
    _selectedImageModelId = widget.initialImageModelId;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.characterEdit;
    final colorScheme = Theme.of(context).colorScheme;
    final modelsAsync = ref.watch(aiModelsProvider);
    final imageModels = _enabledImageModels(
      modelsAsync.whenOrNull(data: (items) => items) ?? const [],
    );
    _ensureSelectedImageModel(imageModels);

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.avatarGenerateTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            translations.avatarImageModelLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (imageModels.isEmpty)
            Text(
              translations.avatarNoImageModel,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey(
                'character_avatar_image_model_$_selectedImageModelId',
              ),
              initialValue: _selectedImageModelId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              hint: Text(
                translations.avatarImageModelHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              items: [
                for (final model in imageModels)
                  DropdownMenuItem<String>(
                    value: model.id,
                    child: Text(
                      '${model.name} (${model.model})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _isGenerating
                  ? null
                  : (next) {
                      setState(() => _selectedImageModelId = next);
                    },
            ),
          const SizedBox(height: 16),
          Text(
            translations.avatarAspectRatioLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<_AvatarAspectRatio>(
            segments: [
              ButtonSegment(
                value: _AvatarAspectRatio.ratio16x9,
                label: Text(
                  translations.avatarAspectRatio16x9,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment(
                value: _AvatarAspectRatio.ratio4x3,
                label: Text(
                  translations.avatarAspectRatio4x3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment(
                value: _AvatarAspectRatio.ratio1x1,
                label: Text(
                  translations.avatarAspectRatio1x1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            selected: {_aspectRatio},
            onSelectionChanged: _isGenerating
                ? null
                : (selected) {
                    if (selected.isEmpty) {
                      return;
                    }
                    setState(() => _aspectRatio = selected.first);
                  },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _promptController,
            enabled: !_isGenerating,
            minLines: 4,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            labelText: translations.avatarPromptLabel,
            hintText: translations.avatarPromptHint,
          ),
          if (_isGenerating) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isGenerating || imageModels.isEmpty ? null : _generate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: Icon(
              _isGenerating ? LucideIcons.loaderCircle : LucideIcons.sparkles,
            ),
            label: Text(
              _isGenerating
                  ? translations.avatarGenerating
                  : translations.avatarGenerate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _ensureSelectedImageModel(List<AiModelEntity> imageModels) {
    if (imageModels.isEmpty) {
      if (_selectedImageModelId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          setState(() => _selectedImageModelId = null);
        });
      }
      return;
    }

    final selectedStillValid = imageModels.any(
      (model) => model.id == _selectedImageModelId,
    );
    if (selectedStillValid) {
      return;
    }

    final fallbackId = imageModels.first.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _selectedImageModelId = fallbackId);
    });
  }

  Future<void> _generate() async {
    final translations = context.t.characterEdit;
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      SmartDialog.showToast(translations.avatarPromptRequired);
      return;
    }

    final modelId = _selectedImageModelId;
    if (modelId == null) {
      SmartDialog.showToast(translations.avatarNoImageModel);
      return;
    }

    var shouldReset = true;
    setState(() => _isGenerating = true);
    try {
      final preferences = ref.read(appPreferencesProvider);
      final translationsRoot = context.t;
      final avatarUrl = await ref
          .read(generateCharacterServiceProvider)
          .generateAvatar(
            prompt: prompt,
            imageModelId: modelId,
            size: _aspectRatio.apiSize,
            wrapTemplate: effectivePromptTemplate(
              id: PromptId.avatarImageWrap,
              customPrompts: preferences.customPrompts,
              t: translationsRoot,
            ),
            wrapFallbackTemplate: defaultPromptTemplate(
              translationsRoot,
              PromptId.avatarImageWrap,
            ),
          );
      if (!mounted) {
        return;
      }
      if (avatarUrl == null) {
        SmartDialog.showToast(translations.avatarGenerateFailed);
        return;
      }
      shouldReset = false;
      Navigator.of(context).pop(avatarUrl);
    } finally {
      if (shouldReset && mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}
