/// 世界书领域快照（含条目），用于匹配注入与导入导出。
class WorldBook {
  const WorldBook({
    required this.id,
    this.name = '',
    this.description = '',
    this.scanDepth = 50,
    this.tokenBudget = 2000,
    this.recursiveScanning = false,
    this.entries = const [],
  });

  final String id;
  final String name;
  final String description;
  final int scanDepth;
  final int tokenBudget;
  final bool recursiveScanning;
  final List<WorldBookEntry> entries;

  bool get isEmpty => entries.isEmpty;

  WorldBook copyWith({
    String? id,
    String? name,
    String? description,
    int? scanDepth,
    int? tokenBudget,
    bool? recursiveScanning,
    List<WorldBookEntry>? entries,
  }) {
    return WorldBook(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      scanDepth: scanDepth ?? this.scanDepth,
      tokenBudget: tokenBudget ?? this.tokenBudget,
      recursiveScanning: recursiveScanning ?? this.recursiveScanning,
      entries: entries ?? this.entries,
    );
  }
}

/// 世界书条目插入位置。
enum WorldBookPosition { beforeChar, afterChar }

/// 选择性次级关键词逻辑。
enum WorldBookSelectiveLogic { and, or }

/// 单条世界书条目领域模型。
class WorldBookEntry {
  const WorldBookEntry({
    required this.id,
    required this.worldBookId,
    this.name = '',
    this.keys = const [],
    this.secondaryKeys = const [],
    this.content = '',
    this.enabled = true,
    this.constant = false,
    this.selective = false,
    this.selectiveLogic = WorldBookSelectiveLogic.and,
    this.insertionOrder = 100,
    this.priority = 10,
    this.position = WorldBookPosition.beforeChar,
    this.caseSensitive = false,
    this.probability = 100,
    this.useProbability = false,
    this.depth = 4,
    this.weight = 10,
    this.comment = '',
  });

  final String id;
  final String worldBookId;
  final String name;
  final List<String> keys;
  final List<String> secondaryKeys;
  final String content;
  final bool enabled;
  final bool constant;
  final bool selective;
  final WorldBookSelectiveLogic selectiveLogic;
  final int insertionOrder;
  final int priority;
  final WorldBookPosition position;
  final bool caseSensitive;
  final int probability;
  final bool useProbability;
  final int depth;
  final int weight;
  final String comment;

  WorldBookEntry copyWith({
    String? id,
    String? worldBookId,
    String? name,
    List<String>? keys,
    List<String>? secondaryKeys,
    String? content,
    bool? enabled,
    bool? constant,
    bool? selective,
    WorldBookSelectiveLogic? selectiveLogic,
    int? insertionOrder,
    int? priority,
    WorldBookPosition? position,
    bool? caseSensitive,
    int? probability,
    bool? useProbability,
    int? depth,
    int? weight,
    String? comment,
  }) {
    return WorldBookEntry(
      id: id ?? this.id,
      worldBookId: worldBookId ?? this.worldBookId,
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
