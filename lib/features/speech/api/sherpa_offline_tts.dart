import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flute_core/log/log.dart';
import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'sherpa_bindings.dart';

part 'sherpa_tts_messages.dart';
part 'sherpa_tts_isolate.dart';
part 'sherpa_tts_config_builder.dart';
part 'sherpa_tts_model_resolver.dart';
part 'sherpa_tts_preflight.dart';
part 'sherpa_tts_reference_audio.dart';

/// 当前适配的离线 TTS 模型家族。
enum TtsModelFamily { vits, matcha, kokoro, pocket, supertonic }

/// `sherpa_onnx` OfflineTts 适配：isolate 内 generateWithConfig，主 isolate 收 PCM 分片。
class SherpaOfflineTts {
  SherpaOfflineTts();

  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _controlPort;
  var _stopped = false;

  Future<void> speak({
    required String modelDir,
    required String text,
    required FutureOr<void> Function(Float32List samples, int sampleRate)
    onChunk,
    int sid = 0,
    double speed = 1.0,
    String? referenceAudioPath,
  }) async {
    await stop();
    _stopped = false;
    Log.d(
      'TTS speak: modelDir=$modelDir, textLength=${text.length}, '
      'sid=$sid, speed=$speed, hasReference=${referenceAudioPath != null}',
      tag: 'SpeechTts',
    );

    final receivePort = ReceivePort();
    _receivePort = receivePort;
    final ready = Completer<SendPort>();
    final done = Completer<void>();
    Object? error;

    receivePort.listen((message) async {
      if (message is SendPort) {
        _controlPort = message;
        if (!ready.isCompleted) {
          ready.complete(message);
        }
        return;
      }
      if (message is _TtsChunkMessage) {
        if (_stopped) {
          return;
        }
        await onChunk(message.samples, message.sampleRate);
        return;
      }
      if (message is _TtsErrorMessage) {
        error = StateError(message.message);
        Log.e('TTS isolate error: ${message.message}', tag: 'SpeechTts');
        if (!done.isCompleted) {
          done.complete();
        }
        return;
      }
      if (message is _TtsDoneMessage) {
        if (!done.isCompleted) {
          done.complete();
        }
      }
    });

    _isolate = await Isolate.spawn(
      _ttsIsolateEntry,
      _TtsIsolateRequest(
        replyPort: receivePort.sendPort,
        modelDir: modelDir,
        text: text,
        sid: sid,
        speed: speed,
        referenceAudioPath: referenceAudioPath,
      ),
      debugName: 'sherpa_tts',
    );

    await ready.future.timeout(const Duration(seconds: 30));
    await done.future;
    await stop();
    if (error != null) {
      throw error!;
    }
    Log.i('TTS speak completed: textLength=${text.length}', tag: 'SpeechTts');
  }

  Future<void> stop() async {
    final hadIsolate = _isolate != null;
    _stopped = true;
    _controlPort?.send(const _TtsStopMessage());
    _controlPort = null;
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    if (hadIsolate) {
      Log.d('TTS stopped', tag: 'SpeechTts');
    }
  }
}
