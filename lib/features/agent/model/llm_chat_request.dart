import 'llm_message.dart';
import 'llm_tool.dart';

/// LLM 响应正文格式约束。
enum LlmResponseFormat { text, jsonObject }

/// 工具选择策略。
enum LlmToolChoiceMode { auto, none, required, function }

/// Chat Completions 的 tool_choice 领域表示。
class LlmToolChoice {
  const LlmToolChoice._(this.mode, [this.functionName]);

  final LlmToolChoiceMode mode;
  final String? functionName;

  static const auto = LlmToolChoice._(LlmToolChoiceMode.auto);
  static const none = LlmToolChoice._(LlmToolChoiceMode.none);
  static const required = LlmToolChoice._(LlmToolChoiceMode.required);

  factory LlmToolChoice.function(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    return LlmToolChoice._(LlmToolChoiceMode.function, trimmed);
  }
}

/// Chat Completions / Responses 创建请求（领域层）。
class LlmChatRequest {
  const LlmChatRequest({
    required this.model,
    required this.messages,
    this.tools,
    this.toolChoice,
    this.parallelToolCalls,
    this.maxTokens,
    this.maxCompletionTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.includeUsageInStream = false,
    this.responseFormat,
    this.onRemoteResponseId,
  });

  final String model;
  final List<LlmMessage> messages;
  final List<LlmToolDefinition>? tools;
  final LlmToolChoice? toolChoice;
  final bool? parallelToolCalls;
  final int? maxTokens;
  final int? maxCompletionTokens;
  final double? temperature;
  final double? topP;
  final int? topK;
  final bool includeUsageInStream;
  final LlmResponseFormat? responseFormat;

  /// Responses background 任务创建后立刻回调服务端 `response.id`，供落库取回。
  final void Function(String remoteResponseId)? onRemoteResponseId;
}
