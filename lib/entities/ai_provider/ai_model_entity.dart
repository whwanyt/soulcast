import 'package:isar_plus/isar_plus.dart';

part 'ai_model_entity.g.dart';

/// 归属于 AI 服务商的本地模型配置实体。
@collection
class AiModelEntity {
  AiModelEntity({
    required this.id,
    required this.providerId,
    required this.name,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    this.isEnabled = true,
    this.inputFormats = const [],
    this.outputFormats = const [],
  });

  final String id;

  @Index(hash: true)
  final String providerId;

  String name;
  String model;
  bool isEnabled;

  /// 输入格式标签，如 `text` / `image`；空表示未标注。
  List<String> inputFormats;

  /// 输出格式标签，如 `text` / `image`；空表示未标注。
  List<String> outputFormats;

  @Index()
  DateTime createdAt;

  @Index()
  DateTime updatedAt;

  bool hasInputFormat(String tag) => inputFormats.contains(tag);

  bool hasOutputFormat(String tag) => outputFormats.contains(tag);

  AiModelEntity copyWith({
    String? providerId,
    String? name,
    String? model,
    bool? isEnabled,
    List<String>? inputFormats,
    List<String>? outputFormats,
    DateTime? updatedAt,
  }) {
    return AiModelEntity(
      id: id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      model: model ?? this.model,
      isEnabled: isEnabled ?? this.isEnabled,
      inputFormats: inputFormats ?? this.inputFormats,
      outputFormats: outputFormats ?? this.outputFormats,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
