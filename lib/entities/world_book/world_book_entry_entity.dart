import 'package:isar_plus/isar_plus.dart';

part 'world_book_entry_entity.g.dart';

/// 世界书条目的本地持久化实体。
@collection
class WorldBookEntryEntity {
  WorldBookEntryEntity({
    required this.id,
    required this.worldBookId,
    this.name = '',
    this.keys = const [],
    this.secondaryKeys = const [],
    this.content = '',
    this.enabled = true,
    this.constant = false,
    this.selective = false,
    this.selectiveLogic = 'and',
    this.insertionOrder = 100,
    this.priority = 10,
    this.position = 'before_char',
    this.caseSensitive = false,
    this.probability = 100,
    this.useProbability = false,
    this.depth = 4,
    this.weight = 10,
    this.comment = '',
  });

  final String id;

  @Index(hash: true)
  final String worldBookId;

  String name;
  List<String> keys;
  List<String> secondaryKeys;
  String content;
  bool enabled;
  bool constant;
  bool selective;

  /// `and` | `or`
  String selectiveLogic;

  int insertionOrder;
  int priority;

  /// `before_char` | `after_char`
  String position;

  bool caseSensitive;
  int probability;
  bool useProbability;
  int depth;
  int weight;
  String comment;

  WorldBookEntryEntity copyWith({
    String? name,
    List<String>? keys,
    List<String>? secondaryKeys,
    String? content,
    bool? enabled,
    bool? constant,
    bool? selective,
    String? selectiveLogic,
    int? insertionOrder,
    int? priority,
    String? position,
    bool? caseSensitive,
    int? probability,
    bool? useProbability,
    int? depth,
    int? weight,
    String? comment,
  }) {
    return WorldBookEntryEntity(
      id: id,
      worldBookId: worldBookId,
      name: name ?? this.name,
      keys: keys ?? this.keys,
      secondaryKeys: secondaryKeys ?? this.secondaryKeys,
      content: content ?? this.content,
      enabled: enabled ?? this.enabled,
      constant: constant ?? this.constant,
      selective: selective ?? this.selective,
      selectiveLogic: selectiveLogic ?? this.selectiveLogic,
      insertionOrder: insertionOrder ?? this.insertionOrder,
      priority: priority ?? this.priority,
      position: position ?? this.position,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      probability: probability ?? this.probability,
      useProbability: useProbability ?? this.useProbability,
      depth: depth ?? this.depth,
      weight: weight ?? this.weight,
      comment: comment ?? this.comment,
    );
  }
}
