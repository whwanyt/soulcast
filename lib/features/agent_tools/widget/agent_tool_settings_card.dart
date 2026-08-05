import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

import '../model/agent_tool_config.dart';
import '../service/agent_tool.dart';

/// 单个 Agent 工具的说明与扩展参数设置卡片。
class AgentToolSettingsCard extends StatelessWidget {
  const AgentToolSettingsCard({
    super.key,
    required this.tool,
    required this.config,
    required this.onParamChanged,
  });

  final AgentTool tool;
  final AgentToolConfig config;
  final void Function(String key, String value) onParamChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tool.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              tool.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            for (final field in tool.settingFields) ...[
              const SizedBox(height: 12),
              switch (field.type) {
                AgentToolSettingFieldType.text => AgentToolSettingFieldEditor(
                  toolName: tool.name,
                  field: field,
                  value: config.stringParam(field.key) ?? '',
                  onChanged: (value) => onParamChanged(field.key, value),
                ),
                AgentToolSettingFieldType.modelByOutputFormat =>
                  AgentToolModelByOutputFormatField(
                    toolName: tool.name,
                    field: field,
                    value: config.stringParam(field.key) ?? '',
                    onChanged: (value) => onParamChanged(field.key, value),
                  ),
              },
            ],
          ],
        ),
      ),
    );
  }
}

/// 文本型工具参数编辑器，支持敏感字段显隐。
class AgentToolSettingFieldEditor extends StatefulWidget {
  const AgentToolSettingFieldEditor({
    super.key,
    required this.toolName,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final String toolName;
  final AgentToolSettingField field;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<AgentToolSettingFieldEditor> createState() =>
      _AgentToolSettingFieldEditorState();
}

class _AgentToolSettingFieldEditorState
    extends State<AgentToolSettingFieldEditor> {
  late final TextEditingController _controller;
  var _isSecretVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AgentToolSettingFieldEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.agentToolSettings;
    final obscure = widget.field.obscureText && !_isSecretVisible;

    return AppTextField(
      key: ValueKey(
        'agent_tool_setting_${widget.toolName}_${widget.field.key}',
      ),
      controller: _controller,
      labelText: widget.field.label,
      hintText: widget.field.hintText,
      obscureText: obscure,
      onChanged: widget.onChanged,
      suffixIcon: widget.field.obscureText
          ? IconButton(
              tooltip: _isSecretVisible
                  ? translations.hideSecret
                  : translations.showSecret,
              onPressed: () {
                setState(() {
                  _isSecretVisible = !_isSecretVisible;
                });
              },
              icon: Icon(
                _isSecretVisible ? LucideIcons.eyeOff : LucideIcons.eye,
              ),
            )
          : null,
    );
  }
}

/// 从具备指定输出格式的已启用模型中选择工具模型。
class AgentToolModelByOutputFormatField extends ConsumerWidget {
  const AgentToolModelByOutputFormatField({
    super.key,
    required this.toolName,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final String toolName;
  final AgentToolSettingField field;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = t.agent.generateImage;
    final colorScheme = Theme.of(context).colorScheme;
    final requiredTag = field.requiredOutputFormat;
    final modelsAsync = ref.watch(aiModelsProvider);

    return modelsAsync.when(
      data: (models) {
        final candidates =
            models
                .where(
                  (model) =>
                      model.isEnabled &&
                      requiredTag != null &&
                      model.hasOutputFormat(requiredTag),
                )
                .toList(growable: false)
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

        final selectedId = value.trim().isEmpty ? null : value.trim();
        final selectedStillValid =
            selectedId != null &&
            candidates.any((model) => model.id == selectedId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              field.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (field.hintText != null) ...[
              const SizedBox(height: 4),
              Text(
                field.hintText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (candidates.isEmpty)
              Text(
                '${translations.imageModelEmpty}\n${translations.imageModelEmptyHint}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'agent_tool_model_${toolName}_${field.key}_$selectedId',
                ),
                initialValue: selectedStillValid ? selectedId : null,
                isExpanded: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                hint: Text(
                  field.hintText ?? translations.imageModelHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                items: [
                  for (final model in candidates)
                    DropdownMenuItem<String>(
                      value: model.id,
                      child: Text(
                        '${model.name} (${model.model})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (next) => onChanged(next ?? ''),
              ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(
        error.toString(),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),
    );
  }
}
