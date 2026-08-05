/// AI 服务商聊天请求协议。
enum AiProviderApiMode {
  /// OpenAI Chat Completions（`/chat/completions`）。
  chatCompletions,

  /// OpenAI Responses（`/responses`）；可另开 background 取回。
  responses,
}

/// 解析持久化 / 传输用的 apiMode 字符串。
AiProviderApiMode parseAiProviderApiMode(String? raw) {
  final value = raw?.trim();
  for (final mode in AiProviderApiMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }
  throw FormatException('Invalid AiProviderApiMode: $raw');
}
