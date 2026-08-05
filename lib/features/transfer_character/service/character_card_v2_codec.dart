import 'dart:convert';

import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/world_book/world_book.dart';

import '../model/character_card_v2_data.dart';

/// 角色卡 JSON 校验错误类型。
enum CharacterCardJsonError {
  invalidJson,
  invalidSpec,
  missingName,
  invalidFields,
}

/// 携带可本地化错误类型的角色卡 JSON 异常。
class CharacterCardJsonException implements Exception {
  const CharacterCardJsonException(this.error);

  final CharacterCardJsonError error;
}

/// 编解码 SillyTavern `chara_card_v2` JSON。
class CharacterCardV2Codec {
  const CharacterCardV2Codec();

  CharacterCardV2Data decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const CharacterCardJsonException(
        CharacterCardJsonError.invalidJson,
      );
    }

    if (decoded is! Map) {
      throw const CharacterCardJsonException(
        CharacterCardJsonError.invalidJson,
      );
    }
    final root = decoded.cast<String, dynamic>();

    final spec = _readString(root['spec'])?.toLowerCase();
    if (spec != null && spec != 'chara_card_v2' && spec != 'chara_card_v3') {
      throw const CharacterCardJsonException(
        CharacterCardJsonError.invalidSpec,
      );
    }

    final dataRaw = root['data'];
    final Map<String, dynamic> data;
    if (dataRaw is Map) {
      data = dataRaw.cast<String, dynamic>();
    } else if (root.containsKey('name')) {
      data = root;
    } else {
      throw const CharacterCardJsonException(
        CharacterCardJsonError.invalidFields,
      );
    }

    final name = _readString(data['name']);
    if (name == null || name.isEmpty) {
      throw const CharacterCardJsonException(
        CharacterCardJsonError.missingName,
      );
    }

    final bookRaw = data['character_book'];
    WorldBook? book;
    if (bookRaw is Map) {
      final tempId =
          'world_book_import_${DateTime.now().microsecondsSinceEpoch}';
      book = worldBookFromJson(
        bookRaw.cast<String, dynamic>(),
        worldBookId: tempId,
      );
    }

    final extensions = data['extensions'];
    final soulcast = extensions is Map
        ? (extensions['soulcast'] is Map
              ? (extensions['soulcast'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{})
        : const <String, dynamic>{};

    return CharacterCardV2Data(
      name: name,
      description: _readString(data['description']) ?? '',
      personality: _readString(data['personality']) ?? '',
      scenario: _readString(data['scenario']) ?? '',
      firstMes: _readString(data['first_mes']) ?? '',
      mesExample: _readString(data['mes_example']) ?? '',
      systemPrompt: _readString(data['system_prompt']) ?? '',
      postHistoryInstructions:
          _readString(data['post_history_instructions']) ?? '',
      creatorNotes: _readString(data['creator_notes']) ?? '',
      creator: _readString(data['creator']) ?? '',
      characterVersion: _readString(data['character_version']) ?? '',
      tags: _readStringList(data['tags']),
      alternateGreetings: _readStringList(data['alternate_greetings']),
      characterBook: book,
      avatarUrl: _readString(data['avatar']),
      speechStyle: _readString(soulcast['speechStyle']) ?? '',
      appearance: _readString(soulcast['appearance']) ?? '',
      hardConstraints: _readString(soulcast['hardConstraints']) ?? '',
    );
  }

  String encodeFromCharacter(
    CharacterEntity character, {
    WorldBook? primaryWorldBook,
  }) {
    final greetings = character.nonEmptyGreetings;
    final firstMes = greetings.isEmpty ? '' : greetings.first;
    final alternates = greetings.length <= 1
        ? const <String>[]
        : greetings.sublist(1);

    final book = primaryWorldBook;
    final data = <String, dynamic>{
      'name': character.name,
      'description': character.description,
      'personality': character.personality,
      'scenario': character.scenario,
      'first_mes': firstMes,
      'mes_example': character.exampleDialogues,
      'system_prompt': character.cardSystemPrompt,
      'post_history_instructions': character.postHistoryInstructions,
      'creator_notes': character.creatorNotes,
      'creator': character.creator,
      'character_version': character.characterVersion,
      'tags': character.tags,
      'alternate_greetings': alternates,
      'avatar': _exportAvatarField(character.avatarUrl),
      'extensions': {
        'soulcast': {
          'speechStyle': character.speechStyle,
          'appearance': character.appearance,
          'hardConstraints': character.hardConstraints,
        },
      },
      if (book != null &&
          (!book.isEmpty ||
              book.name.trim().isNotEmpty ||
              book.description.trim().isNotEmpty))
        'character_book': worldBookToJson(book),
    };

    return const JsonEncoder.withIndent(
      '  ',
    ).convert({'spec': 'chara_card_v2', 'spec_version': '2.0', 'data': data});
  }
}

String _exportAvatarField(String? avatarUrl) {
  final trimmed = avatarUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'none';
  }
  final uri = Uri.tryParse(trimmed);
  if (uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https')) {
    return trimmed;
  }
  // 本地 file:// 头像对酒馆无意义，导出占位。
  return 'none';
}

String? _readString(Object? value) {
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
