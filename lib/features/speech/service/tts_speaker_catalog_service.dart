import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flute_core/log/log.dart';
import 'package:path/path.dart' as p;
import 'package:soulcast/shared/model/app_preferences_entity.dart';

import '../model/tts_speaker.dart';

/// 从默认 TTS 模型目录解析可选说话人列表。
///
/// Kokoro 等模型把 `speaker_names` / `id2speaker` / `n_speakers` 写在 ONNX
/// metadata 中。大文件只读头尾，必要时再重叠分块扫描，避免整包读入内存。
class TtsSpeakerCatalogService {
  const TtsSpeakerCatalogService();

  static const int _windowBytes = 4 * 1024 * 1024;
  static const int _chunkOverlap = 64 * 1024;
  static const List<String> _metaKeys = [
    'speaker_names',
    'id2speaker',
    'speaker2id',
    'n_speakers',
  ];

  /// 解析成功返回说话人列表；缺少元数据时返回空列表（由 UI 回退为 sid +/-）。
  Future<List<TtsSpeaker>> listSpeakers(String modelDir) async {
    if (modelDir.isEmpty) {
      return const [];
    }
    final dir = Directory(modelDir);
    if (!dir.existsSync()) {
      return const [];
    }

    final onnxFiles = _listOnnxCandidates(dir);
    if (onnxFiles.isEmpty) {
      Log.d('TTS speaker catalog: no onnx under $modelDir', tag: 'SpeechTts');
      return const [];
    }

    for (final onnx in onnxFiles) {
      try {
        final speakers = await _speakersFromOnnx(onnx);
        if (speakers != null && speakers.isNotEmpty) {
          return speakers;
        }
      } catch (error, stackTrace) {
        Log.e(
          'TTS speaker catalog parse failed: ${onnx.path}, error=$error',
          tag: 'SpeechTts',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    Log.d(
      'TTS speaker catalog: metadata missing under $modelDir, use sid stepper',
      tag: 'SpeechTts',
    );
    return const [];
  }

  Future<List<TtsSpeaker>?> _speakersFromOnnx(File onnx) async {
    final meta = await _readOnnxStringMetadata(onnx);
    final fromNames = _parseSpeakerNames(meta['speaker_names']);
    if (fromNames.isNotEmpty) {
      Log.d(
        'TTS speaker catalog: ${fromNames.length} names from '
        'speaker_names in ${onnx.path}',
        tag: 'SpeechTts',
      );
      return fromNames;
    }

    final fromIdMap = _parseId2Speaker(meta['id2speaker']);
    if (fromIdMap.isNotEmpty) {
      Log.d(
        'TTS speaker catalog: ${fromIdMap.length} names from '
        'id2speaker in ${onnx.path}',
        tag: 'SpeechTts',
      );
      return fromIdMap;
    }

    final fromSpeaker2Id = _parseSpeaker2Id(meta['speaker2id']);
    if (fromSpeaker2Id.isNotEmpty) {
      Log.d(
        'TTS speaker catalog: ${fromSpeaker2Id.length} names from '
        'speaker2id in ${onnx.path}',
        tag: 'SpeechTts',
      );
      return fromSpeaker2Id;
    }

    final n = int.tryParse(meta['n_speakers']?.trim() ?? '');
    if (n != null && n > 0) {
      final maxSid = math.min(n - 1, maxTtsSpeakerId);
      Log.d(
        'TTS speaker catalog: n_speakers=$n from ${onnx.path}',
        tag: 'SpeechTts',
      );
      return _numericRange(minTtsSpeakerId, maxSid);
    }
    return null;
  }

  List<File> _listOnnxCandidates(Directory dir) {
    final candidates = <File>[];
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final lower = p.basename(entity.path).toLowerCase();
      if (!lower.endsWith('.onnx')) {
        continue;
      }
      candidates.add(entity);
    }
    if (candidates.isEmpty) {
      return const [];
    }

    int rank(String lower) {
      if (lower == 'model.onnx') {
        return 0;
      }
      if (lower == 'model.int8.onnx') {
        return 1;
      }
      if (lower.startsWith('model') && lower.endsWith('.onnx')) {
        return 2;
      }
      if (lower.contains('vits') || lower.contains('kokoro')) {
        return 3;
      }
      return 10;
    }

    candidates.sort((a, b) {
      final ra = rank(p.basename(a.path).toLowerCase());
      final rb = rank(p.basename(b.path).toLowerCase());
      if (ra != rb) {
        return ra.compareTo(rb);
      }
      return a.path.compareTo(b.path);
    });
    return candidates;
  }

  Future<Map<String, String>> _readOnnxStringMetadata(File file) async {
    final length = await file.length();
    if (length <= 0) {
      return const {};
    }

    final raf = await file.open(mode: FileMode.read);
    try {
      // 先扫头部与尾部（metadata 可能在 graph 前或后）。
      final headLen = math.min(_windowBytes, length);
      await raf.setPosition(0);
      final head = Uint8List.fromList(await raf.read(headLen));
      var merged = _extractProtobufStringEntries(head);

      if (length > headLen) {
        final tailStart = math.max(0, length - _windowBytes);
        await raf.setPosition(tailStart);
        final tail = Uint8List.fromList(await raf.read(length - tailStart));
        merged = {...merged, ..._extractProtobufStringEntries(tail)};
      }

      if (_hasSpeakerMeta(merged) || length <= _windowBytes * 2) {
        return merged;
      }

      // 头尾都没有时，重叠分块扫全文件（Kokoro 等大包偶发落在中段）。
      Log.d(
        'TTS speaker catalog: head/tail miss, chunk-scan ${file.path} '
        'size=$length',
        tag: 'SpeechTts',
      );
      final step = _windowBytes - _chunkOverlap;
      for (var start = 0; start < length; start += step) {
        final end = math.min(start + _windowBytes, length);
        await raf.setPosition(start);
        final chunk = Uint8List.fromList(await raf.read(end - start));
        final part = _extractProtobufStringEntries(chunk);
        if (part.isNotEmpty) {
          merged = {...merged, ...part};
          if (_hasSpeakerMeta(merged)) {
            return merged;
          }
        }
        if (end >= length) {
          break;
        }
      }
      return merged;
    } finally {
      await raf.close();
    }
  }

  bool _hasSpeakerMeta(Map<String, String> meta) {
    return (meta['speaker_names']?.isNotEmpty ?? false) ||
        (meta['id2speaker']?.isNotEmpty ?? false) ||
        (meta['speaker2id']?.isNotEmpty ?? false) ||
        (meta['n_speakers']?.isNotEmpty ?? false);
  }

  /// 扫描 `StringStringEntryProto` 风格的 key/value。
  Map<String, String> _extractProtobufStringEntries(Uint8List bytes) {
    final out = <String, String>{};
    for (final key in _metaKeys) {
      final value = _readMetaValue(bytes, key);
      if (value != null && value.isNotEmpty) {
        out[key] = value;
      }
    }
    return out;
  }

  String? _readMetaValue(Uint8List bytes, String key) {
    final keyBytes = utf8.encode(key);
    var searchFrom = 0;
    while (searchFrom <= bytes.length - keyBytes.length) {
      final index = _indexOf(bytes, keyBytes, searchFrom);
      if (index < 0) {
        return null;
      }

      // 典型编码：0x0A <keyLen> <key> 0x12 <valueLen...> <value>
      if (index >= 2 &&
          bytes[index - 2] == 0x0A &&
          bytes[index - 1] == keyBytes.length) {
        final afterKey = index + keyBytes.length;
        final value = _readLengthDelimitedString(bytes, afterKey);
        if (value != null && _looksLikeMetaValue(key, value)) {
          return value;
        }
        // 少数文件 value 在 key 之前：回看一小段找 0x12。
        final lookbackStart = math.max(0, index - 8);
        for (var i = lookbackStart; i < index - 1; i++) {
          if (bytes[i] != 0x12) {
            continue;
          }
          final beforeKey = _readLengthDelimitedString(bytes, i + 1);
          if (beforeKey != null && _looksLikeMetaValue(key, beforeKey)) {
            return beforeKey;
          }
        }
      }
      searchFrom = index + 1;
    }
    return null;
  }

  /// [offset] 指向 value 字段 tag `0x12`。
  String? _readLengthDelimitedString(Uint8List bytes, int offset) {
    if (offset >= bytes.length || bytes[offset] != 0x12) {
      return null;
    }
    final (valueLen, next) = _readVarint(bytes, offset + 1);
    if (valueLen <= 0 || next + valueLen > bytes.length) {
      return null;
    }
    return utf8.decode(
      bytes.sublist(next, next + valueLen),
      allowMalformed: true,
    );
  }

  bool _looksLikeMetaValue(String key, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 200000) {
      return false;
    }
    switch (key) {
      case 'n_speakers':
        return int.tryParse(trimmed) != null;
      case 'speaker_names':
        return RegExp(
          r'^[A-Za-z][A-Za-z0-9_]*(?:\s*,\s*[A-Za-z][A-Za-z0-9_]*)+$',
        ).hasMatch(trimmed);
      case 'id2speaker':
        return RegExp(
          r'^\d+\s*->\s*[A-Za-z][A-Za-z0-9_]*(?:\s*,\s*\d+\s*->\s*[A-Za-z][A-Za-z0-9_]*)*$',
        ).hasMatch(trimmed);
      case 'speaker2id':
        return RegExp(
          r'^[A-Za-z][A-Za-z0-9_]*\s*->\s*\d+(?:\s*,\s*[A-Za-z][A-Za-z0-9_]*\s*->\s*\d+)*$',
        ).hasMatch(trimmed);
      default:
        return true;
    }
  }

  List<TtsSpeaker> _parseSpeakerNames(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    final names = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    // 至少 2 个名字才认为是名单，避免误匹配单段噪音。
    if (names.length < 2) {
      return const [];
    }
    final out = <TtsSpeaker>[];
    for (var i = 0; i < names.length; i++) {
      if (i > maxTtsSpeakerId) {
        break;
      }
      out.add(TtsSpeaker(sid: i, name: names[i]));
    }
    return out;
  }

  List<TtsSpeaker> _parseId2Speaker(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    final bySid = <int, String>{};
    for (final part in raw.split(',')) {
      final piece = part.trim();
      if (piece.isEmpty) {
        continue;
      }
      final arrow = piece.indexOf('->');
      if (arrow <= 0 || arrow >= piece.length - 2) {
        continue;
      }
      final sid = int.tryParse(piece.substring(0, arrow).trim());
      final name = piece.substring(arrow + 2).trim();
      if (sid == null ||
          sid < minTtsSpeakerId ||
          sid > maxTtsSpeakerId ||
          name.isEmpty) {
        continue;
      }
      bySid[sid] = name;
    }
    if (bySid.length < 2) {
      return const [];
    }
    final sids = bySid.keys.toList()..sort();
    return [for (final sid in sids) TtsSpeaker(sid: sid, name: bySid[sid]!)];
  }

  List<TtsSpeaker> _parseSpeaker2Id(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    final bySid = <int, String>{};
    for (final part in raw.split(',')) {
      final piece = part.trim();
      if (piece.isEmpty) {
        continue;
      }
      final arrow = piece.indexOf('->');
      if (arrow <= 0 || arrow >= piece.length - 2) {
        continue;
      }
      final name = piece.substring(0, arrow).trim();
      final sid = int.tryParse(piece.substring(arrow + 2).trim());
      if (sid == null ||
          sid < minTtsSpeakerId ||
          sid > maxTtsSpeakerId ||
          name.isEmpty) {
        continue;
      }
      bySid.putIfAbsent(sid, () => name);
    }
    if (bySid.length < 2) {
      return const [];
    }
    final sids = bySid.keys.toList()..sort();
    return [for (final sid in sids) TtsSpeaker(sid: sid, name: bySid[sid]!)];
  }

  List<TtsSpeaker> _numericRange(int minSid, int maxSid) {
    final start = math.max(minSid, minTtsSpeakerId);
    final end = math.min(maxSid, maxTtsSpeakerId);
    if (end < start) {
      return const [];
    }
    return [for (var sid = start; sid <= end; sid++) TtsSpeaker(sid: sid)];
  }

  int _indexOf(Uint8List haystack, List<int> needle, int start) {
    if (needle.isEmpty || start < 0) {
      return -1;
    }
    outer:
    for (var i = start; i <= haystack.length - needle.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          continue outer;
        }
      }
      return i;
    }
    return -1;
  }

  (int, int) _readVarint(Uint8List bytes, int offset) {
    var result = 0;
    var shift = 0;
    var pos = offset;
    while (pos < bytes.length && shift < 35) {
      final byte = bytes[pos++];
      result |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        return (result, pos);
      }
      shift += 7;
    }
    return (0, offset);
  }
}
