import 'llm_tool.dart';

/// Chat Completions 消息角色。
enum LlmMessageRole { system, user, assistant, tool }

/// 多模态用户内容片段。
sealed class LlmContentPart {
  const LlmContentPart();
}

/// 文本内容片段。
class LlmTextContentPart extends LlmContentPart {
  const LlmTextContentPart(this.text);

  final String text;
}

/// 图片 data URL / http(s) URL 内容片段。
class LlmImageUrlContentPart extends LlmContentPart {
  const LlmImageUrlContentPart(this.url);

  final String url;
}

/// Chat Completions 语义下的请求/响应消息（与具体 SDK 无关）。
class LlmMessage {
  const LlmMessage({
    required this.role,
    this.content,
    this.contentParts,
    this.refusal,
    this.toolCalls,
    this.toolCallId,
    this.reasoningContent,
    this.reasoning,
    this.reasoningDetails,
  });

  factory LlmMessage.system(String content) =>
      LlmMessage(role: LlmMessageRole.system, content: content);

  factory LlmMessage.user(
    String content, {
    List<LlmContentPart>? contentParts,
  }) => LlmMessage(
    role: LlmMessageRole.user,
    content: content,
    contentParts: contentParts,
  );

  factory LlmMessage.assistant({
    String? content,
    String? refusal,
    List<LlmToolCall>? toolCalls,
    String? reasoningContent,
    String? reasoning,
    List<String>? reasoningDetails,
  }) => LlmMessage(
    role: LlmMessageRole.assistant,
    content: content,
    refusal: refusal,
    toolCalls: toolCalls,
    reasoningContent: reasoningContent,
    reasoning: reasoning,
    reasoningDetails: reasoningDetails,
  );

  factory LlmMessage.tool({
    required String toolCallId,
    required String content,
  }) => LlmMessage(
    role: LlmMessageRole.tool,
    toolCallId: toolCallId,
    content: content,
  );

  final LlmMessageRole role;
  final String? content;

  /// 用户多模态内容；非空时优先于 [content] 映射到 API。
  final List<LlmContentPart>? contentParts;
  final String? refusal;
  final List<LlmToolCall>? toolCalls;
  final String? toolCallId;
  final String? reasoningContent;
  final String? reasoning;
  final List<String>? reasoningDetails;

  bool get hasContentParts => contentParts != null && contentParts!.isNotEmpty;
}
