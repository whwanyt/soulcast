import 'package:isar_plus/isar_plus.dart';

part 'world_book_entity.g.dart';

/// 世界书元数据的本地持久化实体。
@collection
class WorldBookEntity {
  WorldBookEntity({
    required this.id,
    required this.name,
    this.description = '',
    this.scanDepth = 50,
    this.tokenBudget = 2000,
    this.recursiveScanning = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  String name;
  String description;
  int scanDepth;
  int tokenBudget;
  bool recursiveScanning;

  @Index()
  DateTime createdAt;

  @Index()
  DateTime updatedAt;

  WorldBookEntity copyWith({
    String? name,
    String? description,
    int? scanDepth,
    int? tokenBudget,
    bool? recursiveScanning,
    DateTime? updatedAt,
  }) {
    return WorldBookEntity(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      scanDepth: scanDepth ?? this.scanDepth,
      tokenBudget: tokenBudget ?? this.tokenBudget,
      recursiveScanning: recursiveScanning ?? this.recursiveScanning,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
