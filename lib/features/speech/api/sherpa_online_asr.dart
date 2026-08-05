import 'dart:io';
import 'dart:typed_data';

import 'package:flute_core/log/log.dart';
import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'sherpa_bindings.dart';

/// `sherpa_onnx` OnlineRecognizer 适配；外层禁止直接 import sherpa_onnx。
class SherpaOnlineAsr {
  SherpaOnlineAsr();

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;

  Future<void> open(String modelDir) async {
    close();
    ensureSherpaBindings();
    Log.d('ASR open: modelDir=$modelDir', tag: 'SpeechAsr');
    final files = await _resolveTransducerFiles(modelDir);
    Log.d(
      'ASR resolved: type=${files.modelType}, '
      'encoder=${p.basename(files.encoder)}, '
      'decoder=${p.basename(files.decoder)}, '
      'joiner=${p.basename(files.joiner)}',
      tag: 'SpeechAsr',
    );
    final config = sherpa.OnlineRecognizerConfig(
      model: sherpa.OnlineModelConfig(
        transducer: sherpa.OnlineTransducerModelConfig(
          encoder: files.encoder,
          decoder: files.decoder,
          joiner: files.joiner,
        ),
        tokens: files.tokens,
        modelType: files.modelType,
      ),
      enableEndpoint: true,
    );
    _recognizer = sherpa.OnlineRecognizer(config);
    _stream = _recognizer!.createStream();
    Log.i('ASR recognizer ready', tag: 'SpeechAsr');
  }

  String acceptPcm16(Uint8List bytes, {int sampleRate = 16000}) {
    final recognizer = _recognizer;
    final stream = _stream;
    if (recognizer == null || stream == null) {
      return '';
    }
    final samples = _pcm16ToFloat32(bytes);
    if (samples.isEmpty) {
      return recognizer.getResult(stream).text;
    }
    stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
    while (recognizer.isReady(stream)) {
      recognizer.decode(stream);
    }
    return recognizer.getResult(stream).text;
  }

  String currentText() {
    final recognizer = _recognizer;
    final stream = _stream;
    if (recognizer == null || stream == null) {
      return '';
    }
    return recognizer.getResult(stream).text;
  }

  void resetStream() {
    final recognizer = _recognizer;
    if (recognizer == null) {
      return;
    }
    _stream?.free();
    _stream = recognizer.createStream();
  }

  void close() {
    final hadRecognizer = _recognizer != null;
    _stream?.free();
    _stream = null;
    _recognizer?.free();
    _recognizer = null;
    if (hadRecognizer) {
      Log.d('ASR closed', tag: 'SpeechAsr');
    }
  }

  static Float32List _pcm16ToFloat32(Uint8List bytes) {
    final count = bytes.length ~/ 2;
    if (count == 0) {
      return Float32List(0);
    }
    final data = ByteData.sublistView(bytes);
    final samples = Float32List(count);
    for (var i = 0; i < count; i++) {
      samples[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return samples;
  }

  static Future<_TransducerFiles> _resolveTransducerFiles(
    String modelDir,
  ) async {
    final dir = Directory(modelDir);
    if (!dir.existsSync()) {
      throw StateError('Model directory not found: $modelDir');
    }

    String? tokens;
    final encoders = <String>[];
    final decoders = <String>[];
    final joiners = <String>[];

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path).toLowerCase();
      if (name == 'tokens.txt') {
        tokens = entity.path;
        continue;
      }
      if (!name.endsWith('.onnx')) {
        continue;
      }
      if (name.contains('encoder')) {
        encoders.add(entity.path);
      } else if (name.contains('decoder')) {
        decoders.add(entity.path);
      } else if (name.contains('joiner')) {
        joiners.add(entity.path);
      }
    }

    if (tokens == null ||
        encoders.isEmpty ||
        decoders.isEmpty ||
        joiners.isEmpty) {
      throw StateError(
        'Model directory missing transducer files under $modelDir',
      );
    }

    String preferInt8(List<String> paths) {
      return paths.firstWhere(
        (path) => path.toLowerCase().contains('int8'),
        orElse: () => paths.first,
      );
    }

    String preferNonInt8(List<String> paths) {
      return paths.firstWhere(
        (path) => !path.toLowerCase().contains('int8'),
        orElse: () => paths.first,
      );
    }

    final encoder = preferInt8(encoders);
    // 官方流式 zipformer：encoder/joiner 用 int8，decoder 用浮点。
    // modelType 误设为 zipformer(v1) 会因缺少 attention_dims 直接 abort。
    return _TransducerFiles(
      encoder: encoder,
      decoder: preferNonInt8(decoders),
      joiner: preferInt8(joiners),
      tokens: tokens,
      modelType: _detectOnlineModelType(
        modelDir: modelDir,
        encoderPath: encoder,
      ),
    );
  }

  /// 优先 zipformer2；路径无法判断时留空交给 sherpa 自动探测。
  static String _detectOnlineModelType({
    required String modelDir,
    required String encoderPath,
  }) {
    final haystack = '${modelDir.toLowerCase()} ${encoderPath.toLowerCase()}';
    if (haystack.contains('zipformer2') ||
        haystack.contains('chunk') ||
        haystack.contains('streaming')) {
      return 'zipformer2';
    }
    if (haystack.contains('zipformer') && !haystack.contains('zipformer2')) {
      return 'zipformer';
    }
    // 近年发布的流式 transducer 几乎都是 zipformer2；空串依赖自动探测，
    // 但部分绑定路径不稳定，默认 zipformer2 更安全。
    return 'zipformer2';
  }
}

class _TransducerFiles {
  const _TransducerFiles({
    required this.encoder,
    required this.decoder,
    required this.joiner,
    required this.tokens,
    required this.modelType,
  });

  final String encoder;
  final String decoder;
  final String joiner;
  final String tokens;
  final String modelType;
}
