import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/features/manage_character/manage_character.dart';
import 'package:soulcast/features/manage_world_book/manage_world_book.dart';

import '../model/character_card_v2_data.dart';
import 'character_card_png_reader.dart';
import 'character_card_v2_codec.dart';

/// 编排角色卡文件导入。
class CharacterTransferService {
  const CharacterTransferService({
    this.codec = const CharacterCardV2Codec(),
    this.pngReader = const CharacterCardPngReader(),
  });

  final CharacterCardV2Codec codec;
  final CharacterCardPngReader pngReader;

  Future<CharacterEntity> importFromFile({
    required String path,
    required ManageCharacterService manageCharacter,
    required ManageWorldBookService manageWorldBook,
    Uint8List? bytes,
  }) async {
    final fileBytes = bytes ?? await File(path).readAsBytes();
    final extension = p.extension(path).toLowerCase();
    final String jsonSource;
    Uint8List? pngAvatarBytes;

    if (extension == '.png') {
      jsonSource = pngReader.extractJson(fileBytes);
      pngAvatarBytes = fileBytes;
    } else if (extension == '.json' || extension == '.txt') {
      jsonSource = utf8.decode(fileBytes);
    } else {
      if (_looksLikePng(fileBytes)) {
        jsonSource = pngReader.extractJson(fileBytes);
        pngAvatarBytes = fileBytes;
      } else {
        jsonSource = utf8.decode(fileBytes);
      }
    }

    final data = codec.decode(jsonSource);
    return _persistImportedCard(
      data: data,
      manageCharacter: manageCharacter,
      manageWorldBook: manageWorldBook,
      pngAvatarBytes: pngAvatarBytes,
    );
  }

  Future<CharacterEntity> _persistImportedCard({
    required CharacterCardV2Data data,
    required ManageCharacterService manageCharacter,
    required ManageWorldBookService manageWorldBook,
    Uint8List? pngAvatarBytes,
  }) async {
    final avatarUrl = await _resolveImportAvatar(
      manageCharacter: manageCharacter,
      pngAvatarBytes: pngAvatarBytes,
      cardAvatar: data.avatarUrl,
    );

    final character = await manageCharacter.saveCharacter(
      name: data.name,
      avatarUrl: avatarUrl,
      description: data.description,
      personality: data.personality,
      speechStyle: data.speechStyle,
      appearance: data.appearance,
      scenario: data.scenario,
      greetings: data.greetings,
      exampleDialogues: data.mesExample,
      hardConstraints: data.hardConstraints,
      tags: data.tags,
      creator: data.creator,
      creatorNotes: data.creatorNotes,
      characterVersion: data.characterVersion,
      cardSystemPrompt: data.systemPrompt,
      postHistoryInstructions: data.postHistoryInstructions,
    );

    final book = data.characterBook;
    if (book == null ||
        (book.isEmpty &&
            book.name.trim().isEmpty &&
            book.description.trim().isEmpty)) {
      return character;
    }

    final created = await manageWorldBook.createFromCardBook(book);
    return await manageCharacter.setWorldBookBindings(
          characterId: character.id,
          primaryWorldBookId: created.id,
          extraWorldBookIds: const [],
        ) ??
        character;
  }

  /// PNG 卡优先用图片本身；否则尝试下载/解码 JSON `avatar` 字段。
  Future<String?> _resolveImportAvatar({
    required ManageCharacterService manageCharacter,
    Uint8List? pngAvatarBytes,
    String? cardAvatar,
  }) async {
    if (pngAvatarBytes != null && pngAvatarBytes.isNotEmpty) {
      final uri = await manageCharacter.saveAvatarBytes(pngAvatarBytes);
      return uri.toString();
    }

    final raw = cardAvatar?.trim();
    if (raw == null || raw.isEmpty || _isPlaceholderAvatar(raw)) {
      return null;
    }

    if (raw.startsWith('data:image')) {
      final comma = raw.indexOf(',');
      if (comma > 0 && comma < raw.length - 1) {
        final payload = raw.substring(comma + 1);
        final uri = await manageCharacter.saveAvatarBytes(
          Uint8List.fromList(base64Decode(payload)),
        );
        return uri.toString();
      }
      return null;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    try {
      final saved = await manageCharacter.saveAvatarFromUrl(raw);
      return saved.toString();
    } catch (_) {
      // 下载失败时仍保留远端 URL，界面可走 Image.network。
      return raw;
    }
  }

  bool _isPlaceholderAvatar(String value) {
    final lower = value.toLowerCase();
    return lower == 'none' ||
        lower == 'null' ||
        lower == 'undefined' ||
        lower == 'n/a';
  }

  bool _looksLikePng(Uint8List bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47;
  }
}
