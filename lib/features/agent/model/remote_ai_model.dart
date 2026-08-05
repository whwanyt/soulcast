/// 从远端 `/models` 接口读取的模型摘要。
class RemoteAiModel {
  const RemoteAiModel({required this.id, required this.object, this.ownedBy});

  factory RemoteAiModel.fromJson(Map<String, dynamic> json) {
    return RemoteAiModel(
      id: json['id'] is String ? (json['id'] as String).trim() : '',
      object: json['object'] is String ? json['object'] as String : 'model',
      ownedBy: json['owned_by'] is String ? json['owned_by'] as String : null,
    );
  }

  final String id;
  final String object;
  final String? ownedBy;
}
