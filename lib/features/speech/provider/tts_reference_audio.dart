import 'dart:io';

import '../service/tts_reference_audio_service.dart';

/// 列出当前 TTS 模型内置的参考音频。
List<String> listBundledTtsReferenceAudio(String modelDir) {
  return const TtsReferenceAudioService().listBundled(modelDir);
}

/// 将用户选择的 WAV 导入应用参考音频目录。
Future<String> importTtsReferenceAudio(File source) {
  return const TtsReferenceAudioService().importWav(source);
}
