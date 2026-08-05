part of 'sherpa_offline_tts.dart';

void _preflightTtsConfig(sherpa.OfflineTtsConfig config) {
  void requireOnnx(String path, String label) {
    if (path.isEmpty) {
      return;
    }
    if (!_isPlausibleOnnxFile(path)) {
      throw StateError('Invalid or corrupt TTS $label: $path');
    }
  }

  void requireFile(String path, String label) {
    if (path.isEmpty) {
      return;
    }
    if (!File(path).existsSync()) {
      throw StateError('TTS $label missing: $path');
    }
  }

  requireOnnx(config.model.vits.model, 'vits model');
  requireOnnx(config.model.matcha.acousticModel, 'matcha acoustic');
  requireOnnx(config.model.matcha.vocoder, 'matcha vocoder');
  requireOnnx(config.model.kokoro.model, 'kokoro model');
  requireOnnx(config.model.pocket.lmFlow, 'pocket lm_flow');
  requireOnnx(config.model.pocket.lmMain, 'pocket lm_main');
  requireOnnx(config.model.pocket.encoder, 'pocket encoder');
  requireOnnx(config.model.pocket.decoder, 'pocket decoder');
  requireOnnx(config.model.pocket.textConditioner, 'pocket text_conditioner');
  requireFile(config.model.pocket.vocabJson, 'pocket vocab.json');
  requireFile(config.model.pocket.tokenScoresJson, 'pocket token_scores.json');
  requireOnnx(config.model.supertonic.durationPredictor, 'supertonic duration');
  requireOnnx(config.model.supertonic.textEncoder, 'supertonic text_encoder');
  requireOnnx(
    config.model.supertonic.vectorEstimator,
    'supertonic vector_estimator',
  );
  requireOnnx(config.model.supertonic.vocoder, 'supertonic vocoder');
  requireFile(config.model.supertonic.ttsJson, 'supertonic tts.json');
  requireFile(
    config.model.supertonic.unicodeIndexer,
    'supertonic unicode_indexer',
  );
  requireFile(config.model.supertonic.voiceStyle, 'supertonic voice.bin');
}

/// 删除 melo 冗余 model.int8.onnx（只要同目录树里存在 model.onnx）。
void _purgeRedundantMeloInt8(Directory dir) {
  final modelOnnxPaths = <String>[];
  final modelInt8Files = <File>[];
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final lower = p.basename(entity.path).toLowerCase();
    if (lower == 'model.onnx') {
      modelOnnxPaths.add(entity.path);
    } else if (lower == 'model.int8.onnx') {
      modelInt8Files.add(entity);
    }
  }
  if (modelOnnxPaths.isEmpty || modelInt8Files.isEmpty) {
    return;
  }
  for (final file in modelInt8Files) {
    try {
      file.deleteSync();
      developer.log(
        'Purged redundant melo model.int8.onnx: ${file.path}',
        name: 'SpeechTts',
      );
    } catch (error) {
      developer.log(
        'Failed to purge model.int8.onnx: ${file.path}, error=$error',
        name: 'SpeechTts',
      );
    }
  }
}

/// VITS/Kokoro 禁止加载 melo 的 model.int8.onnx，避免原生 Ort abort。
void _assertSafeVitsModelPath(sherpa.OfflineTtsConfig config) {
  for (final path in [config.model.vits.model, config.model.kokoro.model]) {
    if (path.isEmpty) {
      continue;
    }
    if (p.basename(path).toLowerCase() == 'model.int8.onnx') {
      throw StateError(
        'Refusing to load model.int8.onnx (use model.onnx). '
        'Delete this TTS model and reinstall, or set another default.',
      );
    }
  }
}
