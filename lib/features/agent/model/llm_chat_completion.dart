import 'llm_message.dart';
import 'llm_tool.dart';
import 'llm_usage.dart';

/// 非流式 Chat Completions 响应（领域层）。
class LlmChatCompletion {
  const LlmChatCompletion({
    this.id,
    this.message,
    this.finishReason,
    this.usage,
  });

  final String? id;
  final LlmMessage? message;
  final String? finishReason;
  final LlmUsage? usage;

  String? get text => message?.content;

  String? get refusal => message?.refusal;

  List<LlmToolCall> get toolCalls => message?.toolCalls ?? const [];
}
