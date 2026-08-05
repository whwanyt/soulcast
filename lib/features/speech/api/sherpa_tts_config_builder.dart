part of 'sherpa_offline_tts.dart';

sherpa.OfflineTtsGenerationConfig _buildGenerationConfig({
  required TtsModelFamily family,
  required int sid,
  required double speed,
  String? referenceAudioPath,
  String? fallbackReferenceWav,
}) {
  Float32List? referenceAudio;
  var referenceSampleRate = 0;
  final Map<String, Object> extra = {};
  var numSteps = 5;

  if (family == TtsModelFamily.pocket) {
    final wavPath = _resolveReferenceWavPath(
      preferred: referenceAudioPath,
      fallback: fallbackReferenceWav,
    );
    final wave = sherpa.readWave(wavPath);
    if (wave.samples.isEmpty || wave.sampleRate == 0) {
      throw StateError('Failed to read Pocket reference audio: $wavPath');
    }
    referenceAudio = wave.samples;
    referenceSampleRate = wave.sampleRate;
    numSteps = 2;
    extra['max_reference_audio_len'] = 12;
  } else if (family == TtsModelFamily.supertonic) {
    numSteps = 8;
    extra['lang'] = 'en';
    extra['num_steps'] = 8;
  }

  return sherpa.OfflineTtsGenerationConfig(
    sid: sid,
    speed: speed,
    numSteps: numSteps,
    referenceAudio: referenceAudio,
    referenceSampleRate: referenceSampleRate,
    extra: extra,
  );
}

String _resolveReferenceWavPath({String? preferred, String? fallback}) {
  if (preferred != null &&
      preferred.isNotEmpty &&
      File(preferred).existsSync()) {
    return preferred;
  }
  if (fallback != null && fallback.isNotEmpty && File(fallback).existsSync()) {
    return fallback;
  }
  throw StateError(
    'Pocket TTS needs a reference wav. Set one in Speech output settings.',
  );
}
