import 'package:flute_core/log/log.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';
import 'package:soulcast/i18n/strings.g.dart';

import '../api/mic_pcm_recorder.dart';
import '../api/sherpa_online_asr.dart';
import '../model/speech_input_phase.dart';
import '../model/speech_input_state.dart';

/// 加载当前默认 ASR 模型。
typedef SpeechDefaultModelLoader = Future<SpeechModelEntity?> Function();

/// 协调默认 ASR 模型、麦克风 PCM 流与在线识别器的单次录音会话。
class SpeechInputSession {
  SpeechInputSession({
    required this._loadDefaultModel,
    MicPcmRecorder? recorder,
    SherpaOnlineAsr? asr,
  }) : _recorder = recorder ?? MicPcmRecorder(),
       _asr = asr ?? SherpaOnlineAsr();

  final SpeechDefaultModelLoader _loadDefaultModel;
  final MicPcmRecorder _recorder;
  final SherpaOnlineAsr _asr;

  SpeechInputState _state = const SpeechInputState();
  void Function(SpeechInputState state)? onStateChanged;

  SpeechInputState get state => _state;

  Future<void> toggle() async {
    if (_state.isListening) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    if (_state.isListening) {
      return;
    }

    Log.d('ASR session start', tag: 'SpeechAsr');
    _emit(
      _state.copyWith(
        phase: SpeechInputPhase.starting,
        partialText: '',
        clearError: true,
      ),
    );

    try {
      final model = await _loadDefaultModel();
      if (model == null ||
          model.modelStatus != SpeechModelStatus.ready ||
          model.localDir.isEmpty) {
        Log.w(
          'ASR start aborted: no ready default model '
          '(id=${model?.id}, status=${model?.modelStatus})',
          tag: 'SpeechAsr',
        );
        _emit(
          SpeechInputState(
            phase: SpeechInputPhase.idle,
            errorMessage: t.main.input.noDefaultModel,
          ),
        );
        return;
      }

      final permitted = await _recorder.hasPermission();
      if (!permitted) {
        Log.w(
          'ASR start aborted: microphone permission denied',
          tag: 'SpeechAsr',
        );
        _emit(
          SpeechInputState(
            phase: SpeechInputPhase.idle,
            errorMessage: t.main.input.permissionDenied,
          ),
        );
        return;
      }

      await _asr.open(model.localDir);
      await _recorder.start(
        onData: (bytes) {
          final text = _asr.acceptPcm16(bytes);
          if (_state.phase != SpeechInputPhase.listening &&
              _state.phase != SpeechInputPhase.starting) {
            return;
          }
          _emit(
            _state.copyWith(
              phase: SpeechInputPhase.listening,
              partialText: text,
              clearError: true,
            ),
          );
        },
      );
      Log.i(
        'ASR session listening: modelId=${model.id}, dir=${model.localDir}',
        tag: 'SpeechAsr',
      );
      _emit(
        _state.copyWith(phase: SpeechInputPhase.listening, clearError: true),
      );
    } catch (error, stackTrace) {
      Log.e(
        'ASR session start failed: $error',
        tag: 'SpeechAsr',
        error: error,
        stackTrace: stackTrace,
      );
      await _safeStopHardware();
      _emit(
        SpeechInputState(
          phase: SpeechInputPhase.idle,
          errorMessage: t.main.input.voiceFailed(error: '$error'),
        ),
      );
    }
  }

  Future<String> stop() async {
    if (!_state.isListening) {
      return _state.partialText;
    }
    _emit(_state.copyWith(phase: SpeechInputPhase.stopping));
    final text = _asr.currentText().trim();
    Log.d('ASR session stop: textLength=${text.length}', tag: 'SpeechAsr');
    await _safeStopHardware();
    _emit(SpeechInputState(phase: SpeechInputPhase.idle, partialText: text));
    return text;
  }

  Future<void> dispose() async {
    await _safeStopHardware();
    await _recorder.dispose();
  }

  Future<void> _safeStopHardware() async {
    try {
      await _recorder.stop();
    } catch (error) {
      Log.w('ASR recorder stop ignored: $error', tag: 'SpeechAsr');
    }
    try {
      _asr.close();
    } catch (error) {
      Log.w('ASR close ignored: $error', tag: 'SpeechAsr');
    }
  }

  void _emit(SpeechInputState next) {
    _state = next;
    onStateChanged?.call(next);
  }
}
