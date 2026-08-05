import 'package:isar_plus/isar_plus.dart';

import 'speech_model_kind.dart';
import 'speech_model_status.dart';

part 'speech_model_entity.g.dart';

/// 本地语音模型的安装状态与路径实体。
@collection
class SpeechModelEntity {
  SpeechModelEntity({
    required this.id,
    required this.displayName,
    required this.downloadUrl,
    required this.kind,
    required this.status,
    required this.localDir,
    required this.downloadTaskId,
    required this.bytesTotal,
    required this.bytesReceived,
    required this.errorMessage,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  String displayName;
  String downloadUrl;

  /// [SpeechModelKind.name]
  String kind;

  /// [SpeechModelStatus.name]
  String status;

  String localDir;
  String downloadTaskId;
  int bytesTotal;
  int bytesReceived;
  String errorMessage;
  bool isDefault;

  @Index()
  DateTime createdAt;

  @Index()
  DateTime updatedAt;

  SpeechModelKind get modelKind => SpeechModelKind.parse(kind);

  SpeechModelStatus get modelStatus => SpeechModelStatus.parse(status);

  SpeechModelEntity copyWith({
    String? displayName,
    String? downloadUrl,
    String? kind,
    String? status,
    String? localDir,
    String? downloadTaskId,
    int? bytesTotal,
    int? bytesReceived,
    String? errorMessage,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return SpeechModelEntity(
      id: id,
      displayName: displayName ?? this.displayName,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      localDir: localDir ?? this.localDir,
      downloadTaskId: downloadTaskId ?? this.downloadTaskId,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      errorMessage: errorMessage ?? this.errorMessage,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
