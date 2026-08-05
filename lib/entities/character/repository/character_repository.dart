import 'package:isar_plus/isar_plus.dart';

import '../character_entity.dart';

/// 角色卡的 Isar 读写仓库。
class CharacterRepository {
  const CharacterRepository(this._isar);

  final Isar _isar;

  List<CharacterEntity> getCharacters() {
    return _sortCharacters(
      _isar.collection<String, CharacterEntity>().where().findAll(),
    );
  }

  Stream<List<CharacterEntity>> watchCharacters() {
    return _isar
        .collection<String, CharacterEntity>()
        .where()
        .watch(fireImmediately: true)
        .map(_sortCharacters);
  }

  CharacterEntity? getCharacter(String characterId) {
    return _isar.collection<String, CharacterEntity>().get(characterId);
  }

  CharacterEntity upsertCharacter({
    String? characterId,
    required String name,
    String? avatarUrl,
    required String description,
    required String personality,
    required String speechStyle,
    required String appearance,
    required String scenario,
    required List<String> greetings,
    required String exampleDialogues,
    required String hardConstraints,
    List<String> tags = const [],
    String creator = '',
    String creatorNotes = '',
    String characterVersion = '',
    String cardSystemPrompt = '',
    String postHistoryInstructions = '',
    bool? isFavorite,
  }) {
    final now = DateTime.now();
    final id = characterId ?? createCharacterId();
    late CharacterEntity character;
    _isar.write((isar) {
      final characters = isar.collection<String, CharacterEntity>();
      final existing = characters.get(id);
      character =
          existing?.copyWith(
            name: name.trim(),
            avatarUrl: _normalizeOptional(avatarUrl),
            description: description.trim(),
            personality: personality.trim(),
            speechStyle: speechStyle.trim(),
            appearance: appearance.trim(),
            scenario: scenario.trim(),
            greetings: _normalizeStringList(greetings),
            exampleDialogues: exampleDialogues.trim(),
            hardConstraints: hardConstraints.trim(),
            tags: _normalizeStringList(tags),
            creator: creator.trim(),
            creatorNotes: creatorNotes.trim(),
            characterVersion: characterVersion.trim(),
            cardSystemPrompt: cardSystemPrompt.trim(),
            postHistoryInstructions: postHistoryInstructions.trim(),
            isFavorite: isFavorite ?? existing.isFavorite,
            updatedAt: now,
          ) ??
          CharacterEntity(
            id: id,
            name: name.trim(),
            avatarUrl: _normalizeOptional(avatarUrl),
            description: description.trim(),
            personality: personality.trim(),
            speechStyle: speechStyle.trim(),
            appearance: appearance.trim(),
            scenario: scenario.trim(),
            greetings: _normalizeStringList(greetings),
            exampleDialogues: exampleDialogues.trim(),
            hardConstraints: hardConstraints.trim(),
            tags: _normalizeStringList(tags),
            creator: creator.trim(),
            creatorNotes: creatorNotes.trim(),
            characterVersion: characterVersion.trim(),
            cardSystemPrompt: cardSystemPrompt.trim(),
            postHistoryInstructions: postHistoryInstructions.trim(),
            isFavorite: isFavorite ?? false,
            createdAt: now,
            updatedAt: now,
            lastUsedAt: now,
          );
      characters.put(character);
    });
    return character;
  }

  CharacterEntity? setWorldBookBindings({
    required String characterId,
    String? primaryWorldBookId,
    required List<String> extraWorldBookIds,
  }) {
    late CharacterEntity? result;
    _isar.write((isar) {
      final characters = isar.collection<String, CharacterEntity>();
      final existing = characters.get(characterId);
      if (existing == null) {
        result = null;
        return;
      }
      final primary = _normalizeOptional(primaryWorldBookId);
      final extras = _normalizeStringList(
        extraWorldBookIds,
      ).where((id) => id != primary).toList(growable: false);
      result = existing.copyWith(
        primaryWorldBookId: primary,
        extraWorldBookIds: extras,
        updatedAt: DateTime.now(),
      );
      characters.put(result!);
    });
    return result;
  }

  /// 删除世界书后清理所有角色上的引用。
  void clearWorldBookReferences(String worldBookId) {
    _isar.write((isar) {
      final characters = isar.collection<String, CharacterEntity>();
      for (final character in characters.where().findAll()) {
        final primary = character.primaryWorldBookId;
        final extras = character.extraWorldBookIds;
        final primaryHit = primary == worldBookId;
        final extrasHit = extras.contains(worldBookId);
        if (!primaryHit && !extrasHit) {
          continue;
        }
        characters.put(
          character.copyWith(
            primaryWorldBookId: primaryHit ? null : primary,
            extraWorldBookIds: extras
                .where((id) => id != worldBookId)
                .toList(growable: false),
            updatedAt: DateTime.now(),
          ),
        );
      }
    });
  }

  void setCharacterFavorite({
    required String characterId,
    required bool isFavorite,
  }) {
    _isar.write((isar) {
      final characters = isar.collection<String, CharacterEntity>();
      final existing = characters.get(characterId);
      if (existing == null || existing.isFavorite == isFavorite) {
        return;
      }
      characters.put(
        existing.copyWith(isFavorite: isFavorite, updatedAt: DateTime.now()),
      );
    });
  }

  void markCharacterUsed(String characterId) {
    _isar.write((isar) {
      final characters = isar.collection<String, CharacterEntity>();
      final existing = characters.get(characterId);
      if (existing == null) {
        return;
      }
      characters.put(existing.copyWith(lastUsedAt: DateTime.now()));
    });
  }

  bool deleteCharacter(String characterId) {
    var deleted = false;
    _isar.write((isar) {
      deleted = isar.collection<String, CharacterEntity>().delete(characterId);
    });
    return deleted;
  }

  String createCharacterId() {
    return 'character_${DateTime.now().microsecondsSinceEpoch}';
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  List<String> _normalizeStringList(List<String> values) {
    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

List<CharacterEntity> _sortCharacters(List<CharacterEntity> characters) {
  return [...characters]..sort((first, second) {
    return second.updatedAt.compareTo(first.updatedAt);
  });
}
