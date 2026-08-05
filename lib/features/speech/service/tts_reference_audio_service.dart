import 'dart:io';

import 'package:flute_core/log/log.dart';
import 'package:path/path.dart' as p;
import 'package:soulcast/shared/storage/app_directories.dart';

import '../api/sherpa_offline_tts.dart';

/// Pocket 参考音频：列出模型内置 wav，或导入到 Support 目录。
class TtsReferenceAudioService {
  const TtsReferenceAudioService();

  List<String> listBundled(String modelDir) {
    return listBundledTtsReferenceWavs(modelDir);
  }

  Future<String> importWav(File source) async {
    if (!source.existsSync()) {
      throw StateError('Reference audio not found: ${source.path}');
    }
    final lower = source.path.toLowerCase();
    if (!lower.endsWith('.wav')) {
      throw StateError('Only .wav reference audio is supported');
    }

    final dirs = await AppDirectories.resolve();
    final targetDir = dirs.ttsReference;
    if (!targetDir.existsSync()) {
      await targetDir.create(recursive: true);
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final base = p.basenameWithoutExtension(source.path);
    final safeBase = base.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final target = File(p.join(targetDir.path, '${safeBase}_$stamp.wav'));
    await source.copy(target.path);
    Log.i(
      'TTS reference wav imported: ${source.path} -> ${target.path}',
      tag: 'SpeechTts',
    );
    return target.path;
  }
}
