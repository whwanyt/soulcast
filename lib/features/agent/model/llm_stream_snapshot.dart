import 'llm_tool.dart';
import 'llm_usage.dart';

/// 流式累计快照（每次 chunk 后的完整累计态）。
class LlmStreamSnapshot {
  const LlmStreamSnapshot({
    this.id,
    this.content = '',
    this.refusal = '',
    this.finishReason,
    this.usage,
    this.toolCalls = const [],
    this.reasoningContent = '',
    this.reasoning = '',
    this.reasoningDetailTexts = const [],
  });

  final String? id;
  final String content;
  final String refusal;
  final String? finishReason;
  final LlmUsage? usage;
  final List<LlmToolCall> toolCalls;
  final String reasoningContent;
  final String reasoning;
  final List<String> reasoningDetailTexts;
}
