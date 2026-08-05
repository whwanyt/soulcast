import 'speech_output_phase.dart';

/// 语音输出运行状态及当前播放消息。
class SpeechOutputState {
  const SpeechOutputState({
    this.phase = SpeechOutputPhase.idle,
    this.playingMessageId,
    this.errorMessage,
  });

  final SpeechOutputPhase phase;
  final String? playingMessageId;
  final String? errorMessage;

  bool get isActive =>
      phase == SpeechOutputPhase.synthesizing ||
      phase == SpeechOutputPhase.playing;

  bool isPlayingMessage(String messageId) =>
      isActive && playingMessageId == messageId;

  SpeechOutputState copyWith({
    SpeechOutputPhase? phase,
    String? playingMessageId,
    String? errorMessage,
    bool clearPlayingMessageId = false,
    bool clearError = false,
  }) {
    return SpeechOutputState(
      phase: phase ?? this.phase,
      playingMessageId: clearPlayingMessageId
          ? null
          : (playingMessageId ?? this.playingMessageId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
