import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/world_book/world_book.dart';
import 'package:soulcast/features/transfer_character/transfer_character.dart';

void main() {
  const codec = CharacterCardV2Codec();
  const pngReader = CharacterCardPngReader();

  test('decodes chara_card_v2 with book and alternate greetings', () {
    final source = jsonEncode({
      'spec': 'chara_card_v2',
      'spec_version': '2.0',
      'data': {
        'name': 'Yes, My Liege',
        'description': 'King sandbox',
        'personality': 'decisive',
        'scenario': 'Florin',
        'first_mes': 'What is your command?',
        'mes_example': 'example',
        'system_prompt': 'stay in world',
        'post_history_instructions': 'keep tense',
        'creator': 'horcocks',
        'creator_notes': 'notes',
        'character_version': 'main',
        'tags': ['Fantasy', 'RPG'],
        'alternate_greetings': ['Meet Chandra', 'Meet Medli'],
        'character_book': {
          'name': 'YMLv2',
          'scan_depth': 50,
          'token_budget': 2000,
          'recursive_scanning': false,
          'entries': [
            {
              'id': 1,
              'keys': ['Chandra'],
              'content': 'Military advisor',
              'enabled': true,
              'constant': false,
              'position': 'before_char',
              'priority': 10,
              'insertion_order': 10,
            },
          ],
        },
      },
    });

    final data = codec.decode(source);
    expect(data.name, 'Yes, My Liege');
    expect(data.greetings, [
      'What is your command?',
      'Meet Chandra',
      'Meet Medli',
    ]);
    expect(data.tags, ['Fantasy', 'RPG']);
    expect(data.characterBook, isNotNull);
    expect(data.characterBook!.entries, hasLength(1));
    expect(data.characterBook!.entries.first.keys, ['Chandra']);
    expect(data.systemPrompt, 'stay in world');
  });

  test('decodes avatar url from card data', () {
    final source = jsonEncode({
      'spec': 'chara_card_v2',
      'spec_version': '2.0',
      'data': {
        'name': 'Avatar Hero',
        'avatar':
            'https://avatars.charhub.io/avatars/horcocks/yes-my-liege/chara_card_v2.png',
      },
    });

    final data = codec.decode(source);
    expect(
      data.avatarUrl,
      'https://avatars.charhub.io/avatars/horcocks/yes-my-liege/chara_card_v2.png',
    );
  });

  test('round-trips soulcast extensions through export', () {
    final now = DateTime(2026, 1, 1);
    final character = CharacterEntity(
      id: 'character_1',
      name: 'Sayo',
      description: 'fox shrine maiden',
      personality: 'tsundere',
      speechStyle: 'soft',
      appearance: 'white kimono',
      scenario: 'old temple',
      greetings: const ['Hello', 'Welcome back'],
      exampleDialogues: 'hi',
      hardConstraints: 'no OOC',
      tags: const ['Fantasy'],
      creator: 'me',
      cardSystemPrompt: 'sys',
      postHistoryInstructions: 'post',
      primaryWorldBookId: 'book_1',
      createdAt: now,
      updatedAt: now,
      lastUsedAt: now,
    );
    const primaryBook = WorldBook(
      id: 'book_1',
      name: 'book',
      entries: [
        WorldBookEntry(
          id: '1',
          worldBookId: 'book_1',
          keys: ['temple'],
          content: 'sacred',
        ),
      ],
    );

    final encoded = codec.encodeFromCharacter(
      character,
      primaryWorldBook: primaryBook,
    );
    final decoded = codec.decode(encoded);
    expect(decoded.name, 'Sayo');
    expect(decoded.greetings, ['Hello', 'Welcome back']);
    expect(decoded.speechStyle, 'soft');
    expect(decoded.appearance, 'white kimono');
    expect(decoded.hardConstraints, 'no OOC');
    expect(decoded.characterBook, isNotNull);
    expect(decoded.characterBook!.entries.first.content, 'sacred');
  });

  test('png reader extracts base64 chara tEXt chunk', () {
    final cardJson = jsonEncode({
      'spec': 'chara_card_v2',
      'spec_version': '2.0',
      'data': {'name': 'Png Hero', 'first_mes': 'Hi'},
    });
    final png = _buildPngWithCharaText(cardJson);
    final extracted = pngReader.extractJson(Uint8List.fromList(png));
    final data = codec.decode(extracted);
    expect(data.name, 'Png Hero');
    expect(data.firstMes, 'Hi');
  });

  test('rejects missing name', () {
    expect(
      () => codec.decode('{"spec":"chara_card_v2","data":{"description":"x"}}'),
      throwsA(
        isA<CharacterCardJsonException>().having(
          (error) => error.error,
          'error',
          CharacterCardJsonError.missingName,
        ),
      ),
    );
  });
}

List<int> _buildPngWithCharaText(String json) {
  final bytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

  void addChunk(String type, List<int> data) {
    final typeCodes = type.codeUnits;
    final length = data.length;
    bytes.addAll([
      (length >> 24) & 0xff,
      (length >> 16) & 0xff,
      (length >> 8) & 0xff,
      length & 0xff,
      ...typeCodes,
      ...data,
      0,
      0,
      0,
      0, // CRC ignored by reader
    ]);
  }

  // Minimal IHDR 1x1 RGBA
  addChunk('IHDR', [0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0]);
  final encoded = base64Encode(utf8.encode(json));
  addChunk('tEXt', [...utf8.encode('chara'), 0, ...utf8.encode(encoded)]);
  addChunk('IEND', const []);
  return bytes;
}
