/// 语音模型从下载到可用的生命周期状态。
enum SpeechModelStatus {
  idle,
  queued,
  downloading,
  extracting,
  ready,
  failed;

  static SpeechModelStatus parse(String value) {
    return SpeechModelStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => SpeechModelStatus.idle,
    );
  }
}
