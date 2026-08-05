import 'package:flute_core/log/log.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';
import 'package:soulcast/i18n/strings.g.dart';

import '../api/pcm_stream_player.dart';
import '../api/sherpa_offline_tts.dart';
import '../model/speech_output_phase.dart';
import '../model/speech_output_state.dart';

/// 加载当前默认 TTS 模型。
typedef SpeechDefaultTtsModelLoader = Future<SpeechModelEntity?> Function();

/// 加载当前 TTS 说话人、语速与参考音频选项。
typedef SpeechTtsVoiceOptionsLoader =
    Future<({int sid, double speed, String? referencePath})> Function();

/// 协调默认 TTS 模型、流式语音合成与 PCM 播放的单次朗读会话。
class SpeechOutputSession {
  SpeechOutputSession({
    required this._loadDefaultModel,
    required this._loadVoiceOptions,
    SherpaOfflineTts? tts,
    PcmStreamPlayer? player,
  }) : _tts = tts ?? SherpaOfflineTts(),
       _player = player ?? PcmStreamPlayer();

  final SpeechDefaultTtsModelLoader _loadDefaultModel;
  final SpeechTtsVoiceOptionsLoader _loadVoiceOptions;
  final SherpaOfflineTts _tts;
  final PcmStreamPlayer _player;

  SpeechOutputState _state = const SpeechOutputState();
  void Function(SpeechOutputState state)? onStateChanged;

  SpeechOutputState get state => _state;

  Future<void> toggle({required String messageId, required String text}) async {
    if (_state.isPlayingMessage(messageId)) {
      await stop();
      return;
    }
    await play(messageId: messageId, text: text);
  }

  Future<void> play({required String messageId, required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await stop();
    Log.d(
      'TTS session play: messageId=$messageId, textLength=${trimmed.length}',
      tag: 'SpeechTts',
    );
    _emit(
      SpeechOutputState(
        phase: SpeechOutputPhase.synthesizing,
        playingMessageId: messageId,
      ),
    );

    try {
      final model = await _loadDefaultModel();
      if (model == null ||
          model.modelStatus != SpeechModelStatus.ready ||
          model.localDir.isEmpty) {
        Log.w(
          'TTS play aborted: no ready default model '
          '(id=${model?.id}, status=${model?.modelStatus})',
          tag: 'SpeechTts',
        );
        _emit(
          SpeechOutputState(
            phase: SpeechOutputPhase.idle,
            errorMessage: t.chat.noDefaultTtsModel,
          ),
        );
        return;
      }

      final voice = await _loadVoiceOptions();
      Log.d(
        'TTS voice options: modelId=${model.id}, sid=${voice.sid}, '
        'speed=${voice.speed}, reference=${voice.referencePath}',
        tag: 'SpeechTts',
      );
      var playerStarted = false;
      await _tts.speak(
        modelDir: model.localDir,
        text: trimmed,
        sid: voice.sid,
        speed: voice.speed,
        referenceAudioPath: voice.referencePath,
        onChunk: (samples, sampleRate) async {
          if (!playerStarted) {
            await _player.ensureStarted(sampleRate);
            playerStarted = true;
            _emit(
              _state.copyWith(
                phase: SpeechOutputPhase.playing,
                clearError: true,
              ),
            );
          }
          await _player.feedFloat32(samples);
        },
      );

      Log.i(
        'TTS session play completed: messageId=$messageId',
        tag: 'SpeechTts',
      );
      _emit(const SpeechOutputState(phase: SpeechOutputPhase.idle));
    } catch (error, stackTrace) {
      Log.e(
        'TTS session play failed: messageId=$messageId, error=$error',
        tag: 'SpeechTts',
        error: error,
        stackTrace: stackTrace,
      );
      await _safeStopHardware();
      _emit(
        SpeechOutputState(
          phase: SpeechOutputPhase.idle,
          errorMessage: t.chat.ttsFailed(error: '$error'),
        ),
      );
    }
  }

  Future<void> stop() async {
    if (!_state.isActive && _state.playingMessageId == null) {
      await _safeStopHardware();
      return;
    }
    Log.d(
      'TTS session stop: messageId=${_state.playingMessageId}',
      tag: 'SpeechTts',
    );
    await _safeStopHardware();
    _emit(const SpeechOutputState(phase: SpeechOutputPhase.idle));
  }

  Future<void> dispose() async {
    await stop();
  }

  Future<void> _safeStopHardware() async {
    try {
      await _tts.stop();
    } catch (error) {
      Log.w('TTS stop ignored: $error', tag: 'SpeechTts');
    }
    try {
      await _player.release();
    } catch (error) {
      Log.w('PCM player release ignored: $error', tag: 'SpeechTts');
    }
  }

  void _emit(SpeechOutputState next) {
    _state = next;
    onStateChanged?.call(next);
  }
}
