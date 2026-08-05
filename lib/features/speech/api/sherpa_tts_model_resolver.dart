part of 'sherpa_offline_tts.dart';

_ResolvedTts _resolveTtsBundle(String modelDir) {
  final dir = Directory(modelDir);
  if (!dir.existsSync()) {
    throw StateError('TTS model directory not found: $modelDir');
  }

  _purgeRedundantMeloInt8(dir);

  String? tokens;
  String? voices;
  String? lexicon;
  String? dataDir;
  String? vocabJson;
  String? tokenScoresJson;
  String? ttsJson;
  String? unicodeIndexer;
  String? voiceStyle;
  final onnxByStem = <String, List<String>>{};
  final ruleFsts = <String>[];
  final ruleFars = <String>[];
  final lexicons = <String>[];
  final wavs = <String>[];

  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is Directory) {
      if (p.basename(entity.path).toLowerCase() == 'espeak-ng-data') {
        dataDir = entity.path;
      }
      continue;
    }
    if (entity is! File) {
      continue;
    }
    final name = p.basename(entity.path);
    final lower = name.toLowerCase();
    if (lower == 'tokens.txt') {
      tokens = entity.path;
    } else if (lower == 'voices.bin') {
      voices = entity.path;
    } else if (lower == 'vocab.json') {
      vocabJson = entity.path;
    } else if (lower == 'token_scores.json') {
      tokenScoresJson = entity.path;
    } else if (lower == 'tts.json') {
      ttsJson = entity.path;
    } else if (lower == 'unicode_indexer.bin') {
      unicodeIndexer = entity.path;
    } else if (lower == 'voice.bin') {
      voiceStyle = entity.path;
    } else if (lower == 'lexicon.txt' || lower.startsWith('lexicon')) {
      lexicons.add(entity.path);
    } else if (lower.endsWith('.fst')) {
      ruleFsts.add(entity.path);
    } else if (lower.endsWith('.far')) {
      ruleFars.add(entity.path);
    } else if (lower.endsWith('.wav')) {
      wavs.add(entity.path);
    } else if (lower.endsWith('.onnx')) {
      final stem = _onnxStem(lower);
      onnxByStem.putIfAbsent(stem, () => <String>[]).add(entity.path);
    }
  }

  if (lexicons.isNotEmpty) {
    lexicon = lexicons.join(',');
  }

  final pocketLmFlow = _pickOnnx(onnxByStem, 'lm_flow', preferInt8: true);
  final pocketLmMain = _pickOnnx(onnxByStem, 'lm_main', preferInt8: true);
  final pocketEncoder = _pickOnnx(onnxByStem, 'encoder', preferInt8: true);
  final pocketDecoder = _pickOnnx(onnxByStem, 'decoder', preferInt8: true);
  final pocketTextConditioner = _pickOnnx(
    onnxByStem,
    'text_conditioner',
    preferInt8: true,
  );

  if (vocabJson != null &&
      tokenScoresJson != null &&
      pocketLmFlow != null &&
      pocketLmMain != null &&
      pocketEncoder != null &&
      pocketDecoder != null &&
      pocketTextConditioner != null) {
    return _ResolvedTts(
      family: TtsModelFamily.pocket,
      fallbackReferenceWav: _preferBundledReferenceWav(wavs),
      config: sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          pocket: sherpa.OfflineTtsPocketModelConfig(
            lmFlow: pocketLmFlow,
            lmMain: pocketLmMain,
            encoder: pocketEncoder,
            decoder: pocketDecoder,
            textConditioner: pocketTextConditioner,
            vocabJson: vocabJson,
            tokenScoresJson: tokenScoresJson,
          ),
          numThreads: 2,
          debug: false,
          provider: 'cpu',
        ),
        maxNumSenetences: 1,
      ),
    );
  }

  final durationPredictor = _pickOnnx(
    onnxByStem,
    'duration_predictor',
    preferInt8: true,
  );
  final textEncoder = _pickOnnx(onnxByStem, 'text_encoder', preferInt8: true);
  final vectorEstimator = _pickOnnx(
    onnxByStem,
    'vector_estimator',
    preferInt8: true,
  );
  final supertonicVocoder = _pickOnnx(onnxByStem, 'vocoder', preferInt8: true);

  if (ttsJson != null &&
      unicodeIndexer != null &&
      voiceStyle != null &&
      durationPredictor != null &&
      textEncoder != null &&
      vectorEstimator != null &&
      supertonicVocoder != null) {
    return _ResolvedTts(
      family: TtsModelFamily.supertonic,
      config: sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          supertonic: sherpa.OfflineTtsSupertonicModelConfig(
            durationPredictor: durationPredictor,
            textEncoder: textEncoder,
            vectorEstimator: vectorEstimator,
            vocoder: supertonicVocoder,
            ttsJson: ttsJson,
            unicodeIndexer: unicodeIndexer,
            voiceStyle: voiceStyle,
          ),
          numThreads: 2,
          debug: false,
          provider: 'cpu',
        ),
        maxNumSenetences: 1,
      ),
    );
  }

  final acoustic = _pickOnnx(onnxByStem, 'acoustic', preferInt8: false);
  final matchaVocoder =
      _pickOnnx(onnxByStem, 'vocoder', preferInt8: false) ??
      _pickOnnx(onnxByStem, 'hifigan', preferInt8: false);
  final vitsModel = _pickNamedOnnx(
    onnxByStem,
    preferInt8: false,
    preferredNames: const ['model', 'vits'],
  );

  if (tokens == null ||
      (vitsModel == null && (acoustic == null || matchaVocoder == null))) {
    throw StateError('Unable to resolve TTS model files under $modelDir');
  }

  late final sherpa.OfflineTtsModelConfig modelConfig;
  late final TtsModelFamily family;
  if (voices != null && vitsModel != null) {
    family = TtsModelFamily.kokoro;
    modelConfig = sherpa.OfflineTtsModelConfig(
      kokoro: sherpa.OfflineTtsKokoroModelConfig(
        model: vitsModel,
        voices: voices,
        tokens: tokens,
        dataDir: dataDir ?? '',
        lexicon: lexicon ?? '',
      ),
      numThreads: 2,
      debug: false,
      provider: 'cpu',
    );
  } else if (acoustic != null && matchaVocoder != null) {
    family = TtsModelFamily.matcha;
    modelConfig = sherpa.OfflineTtsModelConfig(
      matcha: sherpa.OfflineTtsMatchaModelConfig(
        acousticModel: acoustic,
        vocoder: matchaVocoder,
        tokens: tokens,
        lexicon: lexicon ?? '',
        dataDir: dataDir ?? '',
      ),
      numThreads: 2,
      debug: false,
      provider: 'cpu',
    );
  } else {
    family = TtsModelFamily.vits;
    modelConfig = sherpa.OfflineTtsModelConfig(
      vits: sherpa.OfflineTtsVitsModelConfig(
        model: vitsModel!,
        tokens: tokens,
        lexicon: lexicon ?? '',
        dataDir: dataDir ?? '',
      ),
      numThreads: 2,
      debug: false,
      provider: 'cpu',
    );
  }

  return _ResolvedTts(
    family: family,
    config: sherpa.OfflineTtsConfig(
      model: modelConfig,
      ruleFsts: ruleFsts.join(','),
      ruleFars: ruleFars.join(','),
      maxNumSenetences: 1,
    ),
  );
}

String _onnxStem(String lowerBasename) {
  var name = lowerBasename;
  if (name.endsWith('.onnx')) {
    name = name.substring(0, name.length - 5);
  }
  if (name.endsWith('.int8')) {
    name = name.substring(0, name.length - 5);
  }
  if (name.endsWith('.fp16')) {
    name = name.substring(0, name.length - 5);
  }
  return name;
}

String? _pickOnnx(
  Map<String, List<String>> byStem,
  String stem, {
  required bool preferInt8,
}) {
  final paths = byStem[stem];
  if (paths == null || paths.isEmpty) {
    return null;
  }
  return _preferOnnx(paths, preferInt8: preferInt8);
}

String? _pickNamedOnnx(
  Map<String, List<String>> byStem, {
  required bool preferInt8,
  required List<String> preferredNames,
}) {
  for (final name in preferredNames) {
    final hit = _pickOnnx(byStem, name, preferInt8: preferInt8);
    if (hit != null) {
      return hit;
    }
  }
  final all = byStem.values.expand((e) => e).toList();
  if (all.isEmpty) {
    return null;
  }
  return _preferOnnx(all, preferInt8: preferInt8);
}

String? _preferOnnx(List<String> paths, {required bool preferInt8}) {
  var plausible = paths.where(_isPlausibleOnnxFile).toList();
  if (plausible.isEmpty) {
    return null;
  }

  // melo 的 model.int8.onnx 在部分机型上会 Ort::Exception abort，禁止作为 VITS 候选。
  if (!preferInt8) {
    plausible = plausible
        .where((path) => p.basename(path).toLowerCase() != 'model.int8.onnx')
        .toList();
    if (plausible.isEmpty) {
      return null;
    }
  }

  final int8 = plausible
      .where((path) => p.basename(path).toLowerCase().contains('int8'))
      .toList();
  final nonInt8 = plausible
      .where((path) => !p.basename(path).toLowerCase().contains('int8'))
      .toList();

  // preferInt8=false 时绝不回退到 int8（旧逻辑会因此加载 model.int8.onnx 并闪退）。
  final List<String> pool;
  if (preferInt8) {
    pool = int8.isNotEmpty ? int8 : plausible;
  } else if (nonInt8.isNotEmpty) {
    pool = nonInt8;
  } else {
    return null;
  }

  int score(String path) {
    final lower = p.basename(path).toLowerCase();
    var value = 0;
    if (lower == 'model.onnx') {
      value += 40;
    }
    if (lower.contains('model') || lower.contains('vits')) {
      value += 20;
    }
    try {
      if (File(path).lengthSync() >= 1024 * 1024) {
        value += 10;
      }
    } catch (_) {
      value -= 1000;
    }
    return value;
  }

  final sorted = [...pool]..sort((a, b) => score(b).compareTo(score(a)));
  return sorted.first;
}

String? _preferBundledReferenceWav(List<String> wavs) {
  if (wavs.isEmpty) {
    return null;
  }
  for (final path in wavs) {
    if (p.basename(path).toLowerCase() == 'bria.wav') {
      return path;
    }
  }
  final inTestWavs = wavs.where((path) {
    final parts = p.split(path).map((e) => e.toLowerCase());
    return parts.contains('test_wavs');
  }).toList();
  if (inTestWavs.isNotEmpty) {
    inTestWavs.sort();
    return inTestWavs.first;
  }
  final sorted = [...wavs]..sort();
  return sorted.first;
}

bool _isPlausibleOnnxFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return false;
  }
  try {
    final length = file.lengthSync();
    if (length < 1024) {
      return false;
    }
    final raf = file.openSync();
    try {
      final header = raf.readSync(64);
      if (header.isEmpty) {
        return false;
      }
      final first = header.first;
      if (first == 0x3c || first == 0x7b || first == 0x5b) {
        return false;
      }
      var printable = 0;
      for (final byte in header) {
        if (byte == 0x09 ||
            byte == 0x0a ||
            byte == 0x0d ||
            (byte >= 0x20 && byte < 0x7f)) {
          printable++;
        }
      }
      if (printable / header.length > 0.92) {
        return false;
      }
      return true;
    } finally {
      raf.closeSync();
    }
  } catch (_) {
    return false;
  }
}
