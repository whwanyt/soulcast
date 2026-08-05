import 'package:openai_dart/openai_dart.dart';

import '../model/llm_chat_completion.dart';
import '../model/llm_chat_request.dart';
import '../model/llm_image_generation.dart';
import '../model/llm_image_request.dart';
import '../model/llm_message.dart';
import '../model/llm_stream_snapshot.dart';
import '../model/llm_tool.dart';
import '../model/llm_usage.dart';

/// 将领域聊天请求映射为 openai_dart 请求。
ChatCompletionCreateRequest toOpenAiChatCompletionRequest(
  LlmChatRequest request,
) {
  final tools = request.tools;
  final openAiTools = tools == null || tools.isEmpty
      ? null
      : tools.map(toOpenAiTool).toList();

  return ChatCompletionCreateRequest(
    model: request.model,
    messages: request.messages.map(toOpenAiMessage).toList(),
    maxTokens: request.maxTokens,
    maxCompletionTokens: request.maxCompletionTokens,
    temperature: request.temperature,
    topP: request.topP,
    topK: request.topK,
    tools: openAiTools,
    toolChoice: _toOpenAiToolChoice(request.toolChoice, openAiTools != null),
    parallelToolCalls: request.parallelToolCalls,
    streamOptions: request.includeUsageInStream
        ? const StreamOptions(includeUsage: true)
        : null,
    responseFormat: switch (request.responseFormat) {
      LlmResponseFormat.jsonObject => ResponseFormat.jsonObject(),
      LlmResponseFormat.text || null => null,
    },
  );
}

ToolChoice? _toOpenAiToolChoice(LlmToolChoice? choice, bool hasTools) {
  if (!hasTools || choice == null) {
    return null;
  }
  return switch (choice.mode) {
    LlmToolChoiceMode.auto => ToolChoice.auto(),
    LlmToolChoiceMode.none => ToolChoice.none(),
    LlmToolChoiceMode.required => ToolChoice.required(),
    LlmToolChoiceMode.function => ToolChoice.function(choice.functionName!),
  };
}

/// 将领域工具定义映射为 OpenAI function tool。
Tool toOpenAiTool(LlmToolDefinition definition) {
  return Tool.function(
    name: definition.name,
    description: definition.description,
    parameters: definition.parameters,
    strict: definition.strict,
  );
}

/// 将领域消息映射为 OpenAI 协议消息。
ChatMessage toOpenAiMessage(LlmMessage message) {
  return switch (message.role) {
    LlmMessageRole.system => ChatMessage.system(message.content ?? ''),
    LlmMessageRole.user => _toOpenAiUserMessage(message),
    LlmMessageRole.assistant => AssistantMessage(
      content: message.content,
      refusal: message.refusal,
      toolCalls: message.toolCalls?.map(toOpenAiToolCall).toList(),
      reasoningContent: message.reasoningContent,
      reasoning: message.reasoning,
    ),
    LlmMessageRole.tool => ChatMessage.tool(
      toolCallId: message.toolCallId ?? '',
      content: message.content ?? '',
    ),
  };
}

ChatMessage _toOpenAiUserMessage(LlmMessage message) {
  final parts = message.contentParts;
  if (parts == null || parts.isEmpty) {
    return ChatMessage.user(message.content ?? '');
  }

  final openAiParts = <ContentPart>[
    for (final part in parts)
      switch (part) {
        LlmTextContentPart(:final text) => ContentPart.text(text),
        LlmImageUrlContentPart(:final url) => ContentPart.imageUrl(url),
      },
  ];
  return ChatMessage.user(openAiParts);
}

/// 将领域工具调用映射为 OpenAI 协议工具调用。
ToolCall toOpenAiToolCall(LlmToolCall call) {
  return ToolCall.functionCall(
    id: call.id,
    call: FunctionCall(name: call.name, arguments: call.arguments),
  );
}

/// 将 OpenAI 非流式完成响应映射为领域结果。
LlmChatCompletion toLlmChatCompletion(ChatCompletion response) {
  final choice = response.firstChoice;
  final message = choice?.message;
  return LlmChatCompletion(
    id: response.id,
    message: message == null ? null : toLlmAssistantMessage(message),
    finishReason: choice?.finishReason?.toJson(),
    usage: toLlmUsage(response.usage),
  );
}

/// 将 OpenAI 助手消息映射为领域消息。
LlmMessage toLlmAssistantMessage(AssistantMessage message) {
  return LlmMessage.assistant(
    content: message.content,
    refusal: message.refusal,
    toolCalls: message.toolCalls?.map(toLlmToolCall).toList(),
    reasoningContent: message.reasoningContent,
    reasoning: message.reasoning,
    reasoningDetails: message.reasoningDetails
        ?.map((detail) => detail.text)
        .whereType<String>()
        .toList(),
  );
}

/// 将 OpenAI 工具调用映射为领域工具调用。
LlmToolCall toLlmToolCall(ToolCall call) {
  return LlmToolCall(
    id: call.id,
    name: call.function.name,
    arguments: call.function.arguments,
  );
}

/// 将 OpenAI token 用量映射为领域快照。
LlmUsage? toLlmUsage(Usage? usage) {
  if (usage == null) {
    return null;
  }
  return LlmUsage(
    promptTokens: usage.promptTokens,
    completionTokens: usage.completionTokens ?? 0,
    totalTokens: usage.totalTokens,
  );
}

/// 将流式累加器映射为可供 UI 消费的完整快照。
LlmStreamSnapshot toLlmStreamSnapshot(ChatStreamAccumulator accumulator) {
  return LlmStreamSnapshot(
    id: accumulator.id,
    content: accumulator.content,
    refusal: accumulator.refusal,
    finishReason: accumulator.finishReason?.toJson(),
    usage: toLlmUsage(accumulator.usage),
    toolCalls: accumulator.toolCalls.map(toLlmToolCall).toList(),
    reasoningContent: accumulator.reasoningContent,
    reasoning: accumulator.reasoning,
    reasoningDetailTexts: [
      for (final choice in accumulator.choices)
        for (final detail in choice.reasoningDetails)
          if (detail.text != null && detail.text!.trim().isNotEmpty)
            detail.text!,
    ],
  );
}

/// 将领域图片生成请求映射为 OpenAI Images 请求。
///
/// 已知枚举尺寸走 [ImageSize]；兼容供应商的自由尺寸字符串则透传 `size` 字段。
ImageGenerationRequest toOpenAiImageGenerationRequest(LlmImageRequest request) {
  final rawSize = request.size?.trim();
  final normalizedSize = (rawSize == null || rawSize.isEmpty) ? null : rawSize;
  final knownSize = _toOpenAiImageSize(normalizedSize);
  if (normalizedSize != null && knownSize == null) {
    return _ImageGenerationRequestWithRawSize(
      prompt: request.prompt,
      model: request.model,
      n: request.n,
      rawSize: normalizedSize,
    );
  }
  return ImageGenerationRequest(
    prompt: request.prompt,
    model: request.model,
    n: request.n,
    size: knownSize,
  );
}

ImageSize? _toOpenAiImageSize(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final size = ImageSize.fromJson(trimmed);
  if (size == ImageSize.unknown) {
    return null;
  }
  return size;
}

/// 透传 openai_dart [ImageSize] 未收录的尺寸字符串。
class _ImageGenerationRequestWithRawSize extends ImageGenerationRequest {
  const _ImageGenerationRequestWithRawSize({
    required super.prompt,
    super.model,
    super.n,
    required this.rawSize,
  });

  final String rawSize;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['size'] = rawSize;
    return json;
  }
}

/// 将首张图映射为领域结果；`url` / `b64_json` 皆无时返回 `null`。
LlmImageGeneration? toLlmImageGeneration(ImageResponse response) {
  if (response.data.isEmpty) {
    return null;
  }
  final image = response.data.first;
  final url = image.url?.trim();
  final b64Json = image.b64Json?.trim();
  final hasUrl = url != null && url.isNotEmpty;
  final hasB64 = b64Json != null && b64Json.isNotEmpty;
  if (!hasUrl && !hasB64) {
    return null;
  }
  final revised = image.revisedPrompt?.trim();
  return LlmImageGeneration(
    url: hasUrl ? url : null,
    b64Json: hasB64 ? b64Json : null,
    revisedPrompt: revised == null || revised.isEmpty ? null : revised,
  );
}
