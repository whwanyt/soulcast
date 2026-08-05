/// 单次模型回复的 token 用量快照。
class ChatUsageSnapshot {
  const ChatUsageSnapshot({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  final int promptTokens;
  final int? completionTokens;
  final int totalTokens;
}
