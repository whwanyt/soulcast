import 'package:isar_plus/isar_plus.dart';

part 'character_entity.g.dart';

/// 角色卡的本地持久化实体。
@collection
class CharacterEntity {
  CharacterEntity({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.description = '',
    this.personality = '',
    this.speechStyle = '',
    this.appearance = '',
    this.scenario = '',
    this.greetings = const [],
    this.exampleDialogues = '',
    this.hardConstraints = '',
    this.tags = const [],
    this.creator = '',
    this.creatorNotes = '',
    this.characterVersion = '',
    this.cardSystemPrompt = '',
    this.postHistoryInstructions = '',
    this.primaryWorldBookId,
    this.extraWorldBookIds = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    required this.lastUsedAt,
  });

  final String id;

  String name;
  String? avatarUrl;
  String description;
  String personality;
  String speechStyle;
  String appearance;
  String scenario;

  /// 开场白列表；`[0]` 为主开场，其余为备选。
  List<String> greetings;

  String exampleDialogues;
  String hardConstraints;
  List<String> tags;
  String creator;
  String creatorNotes;
  String characterVersion;

  /// 角色卡级系统提示（对标 ST `system_prompt`）。
  String cardSystemPrompt;

  /// 历史消息后指令（对标 ST `post_history_instructions`）。
  String postHistoryInstructions;

  /// 主世界书 id；导出角色卡时嵌入此书。
  String? primaryWorldBookId;

  /// 附加世界书 id 列表；不随角色卡导出。
  List<String> extraWorldBookIds;

  @Index()
  bool isFavorite;

  @Index()
  DateTime createdAt;

  @Index()
  DateTime updatedAt;

  @Index()
  DateTime lastUsedAt;

  /// 主开场白；无开场白时为空串。
  String get primaryGreeting {
    for (final greeting in greetings) {
      final trimmed = greeting.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  /// 非空开场白列表（已 trim）。
  List<String> get nonEmptyGreetings {
    return greetings
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  /// 角色绑定的全部世界书 id（primary 在前，extras 去重）。
  List<String> get boundWorldBookIds {
    final ids = <String>[];
    final primary = primaryWorldBookId?.trim();
    if (primary != null && primary.isNotEmpty) {
      ids.add(primary);
    }
    for (final id in extraWorldBookIds) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty && !ids.contains(trimmed)) {
        ids.add(trimmed);
      }
    }
    return ids;
  }

  CharacterEntity copyWith({
    String? name,
    Object? avatarUrl = _unset,
    String? description,
    String? personality,
    String? speechStyle,
    String? appearance,
    String? scenario,
    List<String>? greetings,
    String? exampleDialogues,
    String? hardConstraints,
    List<String>? tags,
    String? creator,
    String? creatorNotes,
    String? characterVersion,
    String? cardSystemPrompt,
    String? postHistoryInstructions,
    Object? primaryWorldBookId = _unset,
    List<String>? extraWorldBookIds,
    bool? isFavorite,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
  }) {
    return CharacterEntity(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl == _unset ? this.avatarUrl : avatarUrl as String?,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      speechStyle: speechStyle ?? this.speechStyle,
      appearance: appearance ?? this.appearance,
      scenario: scenario ?? this.scenario,
      greetings: greetings ?? this.greetings,
      exampleDialogues: exampleDialogues ?? this.exampleDialogues,
      hardConstraints: hardConstraints ?? this.hardConstraints,
      tags: tags ?? this.tags,
      creator: creator ?? this.creator,
      creatorNotes: creatorNotes ?? this.creatorNotes,
      characterVersion: characterVersion ?? this.characterVersion,
      cardSystemPrompt: cardSystemPrompt ?? this.cardSystemPrompt,
      postHistoryInstructions:
          postHistoryInstructions ?? this.postHistoryInstructions,
      primaryWorldBookId: primaryWorldBookId == _unset
          ? this.primaryWorldBookId
          : primaryWorldBookId as String?,
      extraWorldBookIds: extraWorldBookIds ?? this.extraWorldBookIds,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();
