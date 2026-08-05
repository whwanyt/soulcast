import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'character_card_v2_codec.dart';

/// 从 PNG 字节中提取 SillyTavern 内嵌角色卡 JSON。
class CharacterCardPngReader {
  const CharacterCardPngReader();

  static const _pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

  String extractJson(Uint8List bytes) {
    if (bytes.length < 8) {
      throw const CharacterCardJsonException(
        CharacterCardJsonError.invalidFields,
      );
    }
    for (var i = 0; i < _pngSignature.length; i++) {
      if (bytes[i] != _pngSignature[i]) {
        throw const CharacterCardJsonException(
          CharacterCardJsonError.invalidFields,
        );
      }
    }

    var offset = 8;
    while (offset + 12 <= bytes.length) {
      final length =
          (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      final dataStart = offset + 8;
      final dataEnd = dataStart + length;
      if (dataEnd + 4 > bytes.length || length < 0) {
        break;
      }
      final chunkData = bytes.sublist(dataStart, dataEnd);
      if (type == 'tEXt' || type == 'zTXt') {
        final json = _readCharaChunk(type, chunkData);
        if (json != null) {
          return json;
        }
      }
      if (type == 'IEND') {
        break;
      }
      offset = dataEnd + 4;
    }

    throw const CharacterCardJsonException(
      CharacterCardJsonError.invalidFields,
    );
  }

  String? _readCharaChunk(String type, List<int> data) {
    final nullIndex = data.indexOf(0);
    if (nullIndex <= 0) {
      return null;
    }
    final keyword = utf8.decode(
      data.sublist(0, nullIndex),
      allowMalformed: true,
    );
    if (keyword != 'chara' && keyword != 'ccv3') {
      return null;
    }

    List<int> payload;
    if (type == 'tEXt') {
      payload = data.sublist(nullIndex + 1);
    } else {
      // zTXt: compression method (1 byte) + zlib data
      if (nullIndex + 2 >= data.length) {
        return null;
      }
      final compressed = data.sublist(nullIndex + 2);
      try {
        payload = const ZLibDecoder().decodeBytes(compressed);
      } catch (_) {
        return null;
      }
    }

    final encoded = utf8.decode(payload, allowMalformed: true).trim();
    if (encoded.isEmpty) {
      return null;
    }
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      // 少数导出可能直接写入明文 JSON。
      if (encoded.startsWith('{')) {
        return encoded;
      }
      return null;
    }
  }
}
