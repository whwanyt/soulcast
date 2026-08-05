import 'dart:async';
import 'dart:typed_data';

import 'package:flute_core/log/log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// `record` 封装：16kHz / mono / pcm16bits 流采集。
class MicPcmRecorder {
  MicPcmRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  StreamSubscription<List<int>>? _subscription;

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    final granted = status.isGranted || status.isLimited;
    if (!granted) {
      Log.w('Microphone permission denied: status=$status', tag: 'SpeechAsr');
    }
    return granted;
  }

  Future<void> start({required void Function(Uint8List bytes) onData}) async {
    await stop();
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );
    Log.d('Mic recorder start: 16kHz mono pcm16', tag: 'SpeechAsr');
    final stream = await _recorder.startStream(config);
    _subscription = stream.listen((data) {
      if (data.isEmpty) {
        return;
      }
      onData(Uint8List.fromList(data));
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
      Log.d('Mic recorder stopped', tag: 'SpeechAsr');
    }
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }
}
