part of 'sherpa_offline_tts.dart';

void _ttsIsolateEntry(_TtsIsolateRequest request) {
  final controlPort = ReceivePort();
  var stopped = false;
  controlPort.listen((message) {
    if (message is _TtsStopMessage) {
      stopped = true;
    }
  });
  request.replyPort.send(controlPort.sendPort);

  try {
    ensureSherpaBindings();
    final resolved = _resolveTtsBundle(request.modelDir);
    developer.log(
      'TTS isolate resolved family=${resolved.family.name}, '
      'modelDir=${request.modelDir}',
      name: 'SpeechTts',
    );
    _preflightTtsConfig(resolved.config);
    _assertSafeVitsModelPath(resolved.config);
    final tts = sherpa.OfflineTts(resolved.config);
    final sampleRate = tts.sampleRate;
    try {
      final genConfig = _buildGenerationConfig(
        family: resolved.family,
        sid: request.sid,
        speed: request.speed,
        referenceAudioPath: request.referenceAudioPath,
        fallbackReferenceWav: resolved.fallbackReferenceWav,
      );
      tts.generateWithConfig(
        text: request.text,
        config: genConfig,
        onProgress: (samples, _) {
          if (stopped) {
            return 0;
          }
          if (samples.isEmpty) {
            return 1;
          }
          request.replyPort.send(
            _TtsChunkMessage(
              samples: Float32List.fromList(samples),
              sampleRate: sampleRate,
            ),
          );
          return stopped ? 0 : 1;
        },
      );
      request.replyPort.send(const _TtsDoneMessage());
    } finally {
      tts.free();
    }
  } catch (error, stack) {
    request.replyPort.send(_TtsErrorMessage('$error'));
    // Isolate 内无主 isolate 的 Log 实例，用 developer.log 保留诊断信息。
    developer.log(
      'TTS isolate error: $error',
      name: 'SpeechTts',
      error: error,
      stackTrace: stack,
    );
  } finally {
    controlPort.close();
  }
}
