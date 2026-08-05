import 'dart:typed_data';

import 'package:flute_core/log/logger.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

/// `flutter_pcm_sound` 封装：流式喂入 Int16 PCM。
class PcmStreamPlayer {
  var _ready = false;
  var _sampleRate = 0;

  Future<void> ensureStarted(int sampleRate) async {
    if (_ready && _sampleRate == sampleRate) {
      return;
    }
    if (_ready) {
      await release();
    }
    await FlutterPcmSound.setLogLevel(LogLevel.none);
    await FlutterPcmSound.setup(
      sampleRate: sampleRate,
      channelCount: 1,
      iosAudioCategory: IosAudioCategory.playback,
    );
    await FlutterPcmSound.setFeedThreshold(sampleRate ~/ 10);
    _sampleRate = sampleRate;
    _ready = true;
    Log.d('PCM player started: sampleRate=$sampleRate', tag: 'SpeechTts');
  }

  Future<void> feedFloat32(Float32List samples) async {
    if (!_ready || samples.isEmpty) {
      return;
    }
    final int16 = _float32ToInt16(samples);
    await FlutterPcmSound.feed(PcmArrayInt16.fromList(int16));
    FlutterPcmSound.start();
  }

  Future<void> release() async {
    if (!_ready) {
      return;
    }
    FlutterPcmSound.setFeedCallback(null);
    await FlutterPcmSound.release();
    _ready = false;
    _sampleRate = 0;
    Log.d('PCM player released', tag: 'SpeechTts');
  }

  static List<int> _float32ToInt16(Float32List samples) {
    final out = List<int>.filled(samples.length, 0);
    for (var i = 0; i < samples.length; i++) {
      final v = (samples[i] * 32767.0).round().clamp(-32768, 32767);
      out[i] = v;
    }
    return out;
  }
}
