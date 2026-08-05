part of 'provider_detail_widgets.dart';

/// 新建或编辑 AI 服务商连接信息的表单。
class ProviderDetailForm extends StatefulWidget {
  const ProviderDetailForm({
    super.key,
    required this.provider,
    required this.onSaved,
    required this.onDeleted,
  });

  final AiProviderEntity? provider;
  final ValueChanged<ProviderDetailProviderDraft> onSaved;
  final ValueChanged<AiProviderEntity>? onDeleted;

  @override
  State<ProviderDetailForm> createState() => _ProviderDetailFormState();
}

class _ProviderDetailFormState extends State<ProviderDetailForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiPathController;
  late final TextEditingController _apiKeyController;
  bool _isApiKeyVisible = false;
  late AiProviderApiMode _apiMode;
  late bool _backgroundEnabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider?.name ?? '');
    _baseUrlController = TextEditingController(
      text: widget.provider?.baseUrl ?? '',
    );
    _apiPathController = TextEditingController(
      text: widget.provider?.apiPath ?? '',
    );
    _apiKeyController = TextEditingController(
      text: widget.provider?.apiKey ?? '',
    );
    _apiMode =
        widget.provider?.apiModeValue ?? AiProviderApiMode.chatCompletions;
    _backgroundEnabled = widget.provider?.backgroundEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiPathController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.providerSettings;
    final isEditing = widget.provider != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameController,
            labelText: translations.providerName,
            hintText: translations.providerNameHint,
            prefixIcon: const Icon(LucideIcons.building2),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _baseUrlController,
            labelText: translations.baseUrl,
            hintText: translations.baseUrlHint,
            prefixIcon: const Icon(LucideIcons.link),
            validator: _requiredValidator,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _apiPathController,
            labelText: translations.apiPath,
            hintText: translations.apiPathHint,
            prefixIcon: const Icon(LucideIcons.route),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _apiKeyController,
            labelText: translations.apiKey,
            hintText: translations.apiKeyHint,
            prefixIcon: const Icon(LucideIcons.keyRound),
            validator: _requiredValidator,
            obscureText: !_isApiKeyVisible,
            suffixIcon: IconButton(
              tooltip: _isApiKeyVisible
                  ? translations.hideApiKey
                  : translations.showApiKey,
              onPressed: () {
                setState(() {
                  _isApiKeyVisible = !_isApiKeyVisible;
                });
              },
              icon: Icon(
                _isApiKeyVisible ? LucideIcons.eyeOff : LucideIcons.eye,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            translations.apiMode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<AiProviderApiMode>(
            segments: [
              ButtonSegment(
                value: AiProviderApiMode.chatCompletions,
                label: Text(
                  translations.apiModeChatCompletions,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment(
                value: AiProviderApiMode.responses,
                label: Text(
                  translations.apiModeResponses,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            selected: {_apiMode},
            onSelectionChanged: (selected) {
              if (selected.isEmpty) {
                return;
              }
              setState(() {
                _apiMode = selected.first;
                if (_apiMode != AiProviderApiMode.responses) {
                  _backgroundEnabled = false;
                }
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            translations.apiModeHint,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_apiMode == AiProviderApiMode.responses) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                translations.backgroundEnabled,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                translations.backgroundEnabledHint,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              value: _backgroundEnabled,
              onChanged: (value) {
                setState(() {
                  _backgroundEnabled = value;
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: Icon(isEditing ? LucideIcons.save : LucideIcons.plus),
                    label: Text(
                      isEditing
                          ? translations.saveProvider
                          : translations.addProvider,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (widget.provider != null && widget.onDeleted != null) ...[
                const SizedBox(width: 8),
                SizedBox.square(
                  dimension: 48,
                  child: IconButton.filledTonal(
                    tooltip: translations.deleteProvider,
                    onPressed: () => widget.onDeleted!(widget.provider!),
                    icon: const Icon(LucideIcons.trash2),
                  ),
                ),
              ],
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

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSaved(
      ProviderDetailProviderDraft(
        providerId: widget.provider?.id,
        name: _nameController.text,
        baseUrl: _baseUrlController.text,
        apiPath: _apiPathController.text,
        apiKey: _apiKeyController.text,
        apiMode: _apiMode.name,
        backgroundEnabled: _apiMode == AiProviderApiMode.responses
            ? _backgroundEnabled
            : false,
      ),
    );
  }
}
