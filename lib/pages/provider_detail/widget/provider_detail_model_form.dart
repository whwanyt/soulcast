part of 'provider_detail_widgets.dart';

/// 编辑模型标识、启用状态与格式能力的表单。
class ProviderDetailModelForm extends StatefulWidget {
  const ProviderDetailModelForm({
    super.key,
    required this.model,
    required this.onSaved,
  });

  final AiModelEntity? model;
  final Future<void> Function(ProviderDetailModelDraft draft) onSaved;

  @override
  State<ProviderDetailModelForm> createState() =>
      _ProviderDetailModelFormState();
}

class _ProviderDetailModelFormState extends State<ProviderDetailModelForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _modelController;
  late bool _isEnabled;
  late Set<String> _inputFormats;
  late Set<String> _outputFormats;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.model?.name ?? '');
    _modelController = TextEditingController(text: widget.model?.model ?? '');
    _isEnabled = widget.model?.isEnabled ?? true;
    _inputFormats = {...?widget.model?.inputFormats};
    _outputFormats = {...?widget.model?.outputFormats};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.providerSettings;
    final isEditing = widget.model != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameController,
            labelText: translations.modelName,
            hintText: translations.modelNameHint,
            prefixIcon: const Icon(LucideIcons.badge),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _modelController,
            labelText: translations.modelId,
            hintText: translations.modelIdHint,
            prefixIcon: const Icon(LucideIcons.bot),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          ProviderDetailFormatTagSelector(
            label: translations.inputFormats,
            hint: translations.formatTagsHint,
            selected: _inputFormats,
            onChanged: (next) => setState(() => _inputFormats = next),
          ),
          const SizedBox(height: 12),
          ProviderDetailFormatTagSelector(
            label: translations.outputFormats,
            hint: translations.formatTagsHint,
            selected: _outputFormats,
            onChanged: (next) => setState(() => _outputFormats = next),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: Text(
              translations.modelEnabled,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: Icon(isEditing ? LucideIcons.save : LucideIcons.plus),
                    label: Text(
                      isEditing
                          ? translations.saveModel
                          : translations.addModel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _requiredValidator(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return context.t.providerSettings.requiredField;
    }
    return null;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSaving = true);
    try {
      await widget.onSaved(
        ProviderDetailModelDraft(
          modelId: widget.model?.id,
          name: _nameController.text,
          model: _modelController.text,
          isEnabled: _isEnabled,
          inputFormats: _inputFormats.toList(growable: false),
          outputFormats: _outputFormats.toList(growable: false),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
