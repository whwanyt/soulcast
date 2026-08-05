import 'package:isar_plus/isar_plus.dart';

part 'mcp_server_config_entity.g.dart';

/// MCP Server 的本地连接配置实体。
@collection
class McpServerConfigEntity {
  McpServerConfigEntity({
    required this.id,
    required this.name,
    required this.url,
    required this.enabled,
    required this.bearerToken,
    required this.disabledToolNamesJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  String name;
  String url;
  bool enabled;
  String bearerToken;

  /// JSON 字符串数组，存放该 server 下禁用的原始 tool 名。
  String disabledToolNamesJson;

  @Index()
  DateTime createdAt;

  @Index()
  DateTime updatedAt;

  McpServerConfigEntity copyWith({
    String? name,
    String? url,
    bool? enabled,
    String? bearerToken,
    String? disabledToolNamesJson,
    DateTime? updatedAt,
  }) {
    return McpServerConfigEntity(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      enabled: enabled ?? this.enabled,
      bearerToken: bearerToken ?? this.bearerToken,
      disabledToolNamesJson:
          disabledToolNamesJson ?? this.disabledToolNamesJson,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
