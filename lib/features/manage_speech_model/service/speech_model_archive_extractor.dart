import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flute_core/log/log.dart';
import 'package:path/path.dart' as p;
import 'package:soulcast/entities/speech_model/speech_model.dart';

/// 将下载的模型压缩包解压到目标目录，并按 kind 校验必需文件。
///
/// 大包（如 Pocket ~100MB）必须流式解压，禁止 `readAsBytes` + `decodeBytes`，
/// 否则 Android 上容易 OOM 直接闪退。
class SpeechModelArchiveExtractor {
  const SpeechModelArchiveExtractor();

  Future<Directory> extract({
    required File archiveFile,
    required Directory targetDir,
    SpeechModelKind kind = SpeechModelKind.asr,
  }) async {
    if (!archiveFile.existsSync()) {
      throw StateError('Archive not found: ${archiveFile.path}');
    }
    final archiveSize = archiveFile.lengthSync();
    Log.d(
      'Speech model extract: kind=${kind.name}, '
      'archive=${archiveFile.path}, size=$archiveSize, '
      'target=${targetDir.path}',
      tag: 'SpeechModel',
    );
    if (targetDir.existsSync()) {
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);

    await Isolate.run(
      () => _extractArchiveToDiskSync(
        archivePath: archiveFile.path,
        outputPath: targetDir.path,
        kind: kind,
      ),
    );

    if (!await isReadyModelDir(targetDir, kind: kind)) {
      Log.w(
        'Speech model extract validation failed: kind=${kind.name}, '
        'dir=${targetDir.path}',
        tag: 'SpeechModel',
      );
      throw StateError(
        kind == SpeechModelKind.tts
            ? 'Extracted TTS model is missing required files'
            : 'Extracted model is missing tokens.txt or .onnx files',
      );
    }
    Log.d(
      'Speech model extract validated: kind=${kind.name}, dir=${targetDir.path}',
      tag: 'SpeechModel',
    );
    return targetDir;
  }

  Future<bool> isReadyModelDir(
    Directory dir, {
    SpeechModelKind kind = SpeechModelKind.asr,
  }) async {
    if (!dir.existsSync()) {
      return false;
    }
    var hasTokens = false;
    var hasOnnx = false;
    var hasVoices = false;
    var hasEspeakData = false;
    var hasVocabJson = false;
    var hasTokenScoresJson = false;
    var hasTtsJson = false;
    var hasVoiceBin = false;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is Directory) {
        if (p.basename(entity.path).toLowerCase() == 'espeak-ng-data') {
          hasEspeakData = true;
        }
        continue;
      }
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path).toLowerCase();
      if (name == 'tokens.txt') {
        hasTokens = true;
      }
      if (name.endsWith('.onnx')) {
        hasOnnx = true;
      }
      if (name == 'voices.bin' || name.contains('voices')) {
        hasVoices = true;
      }
      if (name == 'vocab.json') {
        hasVocabJson = true;
      }
      if (name == 'token_scores.json') {
        hasTokenScoresJson = true;
      }
      if (name == 'tts.json') {
        hasTtsJson = true;
      }
      if (name == 'voice.bin') {
        hasVoiceBin = true;
      }
    }

    if (kind == SpeechModelKind.tts) {
      final pocketReady = hasOnnx && hasVocabJson && hasTokenScoresJson;
      final supertonicReady = hasOnnx && hasTtsJson && hasVoiceBin;
      final legacyReady = hasOnnx && (hasTokens || hasVoices || hasEspeakData);
      return pocketReady || supertonicReady || legacyReady;
    }
    return hasTokens && hasOnnx;
  }
}

void _extractArchiveToDiskSync({
  required String archivePath,
  required String outputPath,
  required SpeechModelKind kind,
}) {
  Directory? tempDir;
  var archiveWorkPath = archivePath;
  final lower = archivePath.toLowerCase();

  try {
    if (lower.endsWith('.tar.bz2') || lower.endsWith('.tbz2')) {
      tempDir = Directory.systemTemp.createTempSync('soulcast_speech_');
      archiveWorkPath = p.join(tempDir.path, 'temp.tar');
      final input = InputFileStream(archivePath);
      final output = OutputFileStream(archiveWorkPath);
      try {
        BZip2Decoder().decodeStream(input, output);
      } finally {
        input.closeSync();
        output.closeSync();
      }
    } else if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
      tempDir = Directory.systemTemp.createTempSync('soulcast_speech_');
      archiveWorkPath = p.join(tempDir.path, 'temp.tar');
      final input = InputFileStream(archivePath);
      final output = OutputFileStream(archiveWorkPath);
      try {
        GZipDecoder().decodeStream(input, output);
      } finally {
        input.closeSync();
        output.closeSync();
      }
    }

    final workLower = archiveWorkPath.toLowerCase();
    final input = InputFileStream(archiveWorkPath);
    try {
      late final Archive archive;
      if (workLower.endsWith('.zip') || lower.endsWith('.zip')) {
        archive = ZipDecoder().decodeStream(input);
      } else if (workLower.endsWith('.tar') ||
          lower.endsWith('.tar') ||
          lower.endsWith('.tar.bz2') ||
          lower.endsWith('.tbz2') ||
          lower.endsWith('.tar.gz') ||
          lower.endsWith('.tgz')) {
        archive = TarDecoder().decodeStream(input);
      } else {
        throw StateError('Unsupported archive type: $archivePath');
      }

      final outputRoot = p.normalize(outputPath);
      for (final entry in archive) {
        if (!entry.isFile || entry.isSymbolicLink) {
          continue;
        }
        final relative = _stripTopLevel(entry.name);
        if (relative.isEmpty || relative.contains('..')) {
          continue;
        }
        // melo 冗余 int8；Pocket/Supertonic 的 *.int8.onnx 必须保留。
        if (kind == SpeechModelKind.tts &&
            p.basename(relative).toLowerCase() == 'model.int8.onnx') {
          continue;
        }

        final outPath = p.normalize(p.join(outputRoot, relative));
        if (!p.isWithin(outputRoot, outPath)) {
          continue;
        }

        Directory(p.dirname(outPath)).createSync(recursive: true);
        final output = OutputFileStream(outPath);
        try {
          entry.writeContent(output, freeMemory: true);
        } finally {
          output.closeSync();
          entry.clear();
        }
      }
      archive.clear();
    } finally {
      input.closeSync();
    }
  } finally {
    if (tempDir != null && tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }
}

/// 去掉压缩包内单层顶目录前缀，便于落成扁平模型目录。
String _stripTopLevel(String name) {
  final normalized = name.replaceAll('\\', '/');
  final parts = normalized.split('/');
  if (parts.length <= 1) {
    return normalized;
  }
  return parts.skip(1).join('/');
}
