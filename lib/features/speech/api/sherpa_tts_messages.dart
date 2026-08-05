part of 'sherpa_offline_tts.dart';

class _TtsIsolateRequest {
  const _TtsIsolateRequest({
    required this.replyPort,
    required this.modelDir,
    required this.text,
    required this.sid,
    required this.speed,
    this.referenceAudioPath,
  });

  final SendPort replyPort;
  final String modelDir;
  final String text;
  final int sid;
  final double speed;
  final String? referenceAudioPath;
}

class _TtsChunkMessage {
  const _TtsChunkMessage({required this.samples, required this.sampleRate});

  final Float32List samples;
  final int sampleRate;
}

class _TtsDoneMessage {
  const _TtsDoneMessage();
}

class _TtsErrorMessage {
  const _TtsErrorMessage(this.message);

  final String message;
}

class _TtsStopMessage {
  const _TtsStopMessage();
}

class _ResolvedTts {
  const _ResolvedTts({
    required this.config,
    required this.family,
    this.fallbackReferenceWav,
  });

  final sherpa.OfflineTtsConfig config;
  final TtsModelFamily family;
  final String? fallbackReferenceWav;
}
