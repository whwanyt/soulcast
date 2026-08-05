/// LLM 响应返回的 token 用量。
class LlmUsage {
  const LlmUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
}
