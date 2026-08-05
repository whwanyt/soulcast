import 'speech_input_phase.dart';

/// 语音输入运行状态与实时识别文本。
class SpeechInputState {
  const SpeechInputState({
    this.phase = SpeechInputPhase.idle,
    this.partialText = '',
    this.errorMessage,
  });

  final SpeechInputPhase phase;
  final String partialText;
  final String? errorMessage;

  bool get isListening =>
      phase == SpeechInputPhase.listening ||
      phase == SpeechInputPhase.starting ||
      phase == SpeechInputPhase.stopping;

  SpeechInputState copyWith({
    SpeechInputPhase? phase,
    String? partialText,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SpeechInputState(
      phase: phase ?? this.phase,
      partialText: partialText ?? this.partialText,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
