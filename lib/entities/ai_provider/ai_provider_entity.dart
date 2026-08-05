import 'package:isar_plus/isar_plus.dart';

import 'model/ai_provider_api_mode.dart';

part 'ai_provider_entity.g.dart';

/// OpenAI 兼容服务商的连接配置实体。
@collection
class AiProviderEntity {
  AiProviderEntity({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiPath = '',
    required this.apiKey,
    this.apiMode = 'chatCompletions',
    this.backgroundEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  String name;

  /// 服务根地址，不包含末尾斜杠。
  String baseUrl;

  /// 可选 API 路径前缀；非空时以 `/` 开头且不含末尾斜杠。
  String apiPath;
  String apiKey;

  /// [AiProviderApiMode.name]
  String apiMode;

  /// Responses 模式下是否启用 `background` 异步取回；默认关闭。
  bool backgroundEnabled;

  @Index()
  DateTime createdAt;

  @Index()
  DateTime updatedAt;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  AiProviderApiMode get apiModeValue => parseAiProviderApiMode(apiMode);

  /// 仅 Responses + 显式开启时才会 background 取回。
  bool get usesBackgroundResponse =>
      apiModeValue == AiProviderApiMode.responses && backgroundEnabled;

  AiProviderEntity copyWith({
    String? name,
    String? baseUrl,
    String? apiPath,
    String? apiKey,
    String? apiMode,
    bool? backgroundEnabled,
    DateTime? updatedAt,
  }) {
    return AiProviderEntity(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiPath: apiPath ?? this.apiPath,
      apiKey: apiKey ?? this.apiKey,
      apiMode: apiMode ?? this.apiMode,
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
