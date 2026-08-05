/// 单个 Agent 工具的运行开关与扩展参数。
class AgentToolConfig {
  const AgentToolConfig({required this.enabled, this.params = const {}});

  final bool enabled;
  final Map<String, dynamic> params;

  AgentToolConfig copyWith({bool? enabled, Map<String, dynamic>? params}) {
    return AgentToolConfig(
      enabled: enabled ?? this.enabled,
      params: params ?? this.params,
    );
  }

  String? stringParam(String key) {
    final value = params[key];
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// 工具设置字段的 UI 类型。
enum AgentToolSettingFieldType { text, modelByOutputFormat }

/// 工具声明可配置字段，供设置页渲染。
class AgentToolSettingField {
  const AgentToolSettingField({
    required this.key,
    required this.label,
    this.type = AgentToolSettingFieldType.text,
    this.obscureText = false,
    this.hintText,
    this.requiredOutputFormat,
  });

  final String key;
  final String label;
  final AgentToolSettingFieldType type;
  final bool obscureText;
  final String? hintText;

  /// [AgentToolSettingFieldType.modelByOutputFormat] 时必填。
  final String? requiredOutputFormat;
}
