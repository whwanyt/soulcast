import 'package:isar_plus/isar_plus.dart';

part 'agent_tool_config_entity.g.dart';

/// 本地 Agent 工具的启用状态与扩展参数记录。
@collection
class AgentToolConfigEntity {
  AgentToolConfigEntity({
    required this.id,
    required this.enabled,
    required this.paramsJson,
    required this.updatedAt,
  });

  /// 与 `AgentTool.name` 一致，例如 `show_location_map`。
  final String id;

  bool enabled;

  /// 工具扩展参数 JSON，例如 `{"amapKey":"..."}`。
  String paramsJson;

  @Index()
  DateTime updatedAt;

  AgentToolConfigEntity copyWith({
    bool? enabled,
    String? paramsJson,
    DateTime? updatedAt,
  }) {
    return AgentToolConfigEntity(
      id: id,
      enabled: enabled ?? this.enabled,
      paramsJson: paramsJson ?? this.paramsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
