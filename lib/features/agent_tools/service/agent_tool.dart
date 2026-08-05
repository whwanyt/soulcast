import 'package:soulcast/features/agent/llm.dart';

import '../model/agent_tool_config.dart';

/// 可向 LLM 暴露的本地工具契约。
abstract class AgentTool {
  const AgentTool();

  String get name;

  String get displayName;

  String get description;

  Map<String, dynamic>? get parameters => null;

  bool get strict => false;

  /// 设置页可编辑的扩展字段（写入 AgentToolConfig.params）。
  List<AgentToolSettingField> get settingFields => const [];

  LlmToolDefinition get definition {
    return LlmToolDefinition(
      name: name,
      description: description,
      parameters: parameters,
      strict: strict,
    );
  }

  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments);
}
