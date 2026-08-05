/// 语音模型支持的能力类型。
enum SpeechModelKind {
  asr,
  tts;

  static SpeechModelKind parse(String value) {
    return SpeechModelKind.values.firstWhere(
      (item) => item.name == value,
      orElse: () => SpeechModelKind.asr,
    );
  }
}
