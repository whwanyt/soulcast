import 'package:openai_dart/openai_dart.dart';

import '../model/llm_chat_completion.dart';
import '../model/llm_chat_request.dart';
import '../model/llm_message.dart';
import '../model/llm_remote_poll_result.dart';
import '../model/llm_stream_snapshot.dart';
import '../model/llm_tool.dart';
import '../model/llm_usage.dart';

/// 将领域请求映射为 Responses API 创建请求。
CreateResponseRequest toOpenAiCreateResponseRequest(
  LlmChatRequest request, {
  required bool stream,
  required bool background,
}) {
  final tools = request.tools;
  final openAiTools = tools == null || tools.isEmpty
      ? null
      : tools.map(toOpenAiResponseTool).toList();
  final maxOutputTokens = request.maxCompletionTokens ?? request.maxTokens;

  return CreateResponseRequest(
    model: request.model,
    input: toOpenAiResponseInput(request.messages),
    tools: openAiTools,
    toolChoice: _toOpenAiResponseToolChoice(
      request.toolChoice,
      openAiTools != null,
    ),
    parallelToolCalls: request.parallelToolCalls,
    maxOutputTokens: maxOutputTokens != null && maxOutputTokens >= 16
        ? maxOutputTokens
        : null,
    temperature: request.temperature,
    topP: request.topP,
    stream: stream,
    background: background,
    text: switch (request.responseFormat) {
      LlmResponseFormat.jsonObject => const TextConfig(
        format: JsonObjectFormat(),
      ),
      LlmResponseFormat.text || null => null,
    },
  );
}

/// 领域工具定义 → Responses function tool。
ResponseTool toOpenAiResponseTool(LlmToolDefinition definition) {
  return ResponseTool.function(
    name: definition.name,
    description: definition.description,
    parameters: definition.parameters,
    strict: definition.strict,
  );
}

ResponseToolChoice? _toOpenAiResponseToolChoice(
  LlmToolChoice? choice,
  bool hasTools,
) {
  if (!hasTools || choice == null) {
    return null;
  }
  return switch (choice.mode) {
    LlmToolChoiceMode.auto => ResponseToolChoice.auto,
    LlmToolChoiceMode.none => ResponseToolChoice.none,
    LlmToolChoiceMode.required => ResponseToolChoice.required,
    LlmToolChoiceMode.function => ResponseToolChoice.function(
      name: choice.functionName!,
    ),
  };
}

/// 将领域消息列表映射为 Responses input items。
ResponseInput toOpenAiResponseInput(List<LlmMessage> messages) {
  final items = <Item>[];
  for (final message in messages) {
    switch (message.role) {
      case LlmMessageRole.system:
        items.add(MessageItem.systemText(message.content ?? ''));
      case LlmMessageRole.user:
        items.add(_toOpenAiUserItem(message));
      case LlmMessageRole.assistant:
        final content = message.content?.trim();
        if (content != null && content.isNotEmpty) {
          items.add(MessageItem.assistantText(content));
        }
        final toolCalls = message.toolCalls;
        if (toolCalls != null) {
          for (final call in toolCalls) {
            items.add(
              FunctionCallItem(
                callId: call.id,
                name: call.name,
                arguments: call.arguments,
              ),
            );
          }
        }
      case LlmMessageRole.tool:
        items.add(
          FunctionCallOutputItem.string(
            callId: message.toolCallId ?? '',
            output: message.content ?? '',
          ),
        );
    }
  }
  return ResponseInput.items(items);
}

MessageItem _toOpenAiUserItem(LlmMessage message) {
  final parts = message.contentParts;
  if (parts == null || parts.isEmpty) {
    return MessageItem.userText(message.content ?? '');
  }

  return MessageItem.user([
    for (final part in parts)
      switch (part) {
        LlmTextContentPart(:final text) => InputContent.text(text),
        LlmImageUrlContentPart(:final url) => InputContent.imageUrl(url),
      },
  ]);
}

/// Responses → 领域非流式完成结果。
LlmChatCompletion toLlmChatCompletionFromResponse(Response response) {
  final toolCalls = [
    for (final call in response.functionCalls)
      LlmToolCall(id: call.callId, name: call.name, arguments: call.arguments),
  ];
  final text = response.outputText;
  final reasoning = _reasoningFromResponse(response);

  return LlmChatCompletion(
    id: response.id,
    message: LlmMessage.assistant(
      content: text.isEmpty ? null : text,
      toolCalls: toolCalls.isEmpty ? null : toolCalls,
      reasoningContent: reasoning,
      reasoning: reasoning,
    ),
    finishReason: _finishReasonFromResponse(response),
    usage: toLlmUsageFromResponseUsage(response.usage),
  );
}

String? _reasoningFromResponse(Response response) {
  final buffer = StringBuffer();
  for (final item in response.output) {
    if (item is ReasoningItem) {
      for (final part in item.summary) {
        final text = part.text.trim();
        if (text.isNotEmpty) {
          if (buffer.isNotEmpty) {
            buffer.writeln();
          }
          buffer.write(text);
        }
      }
    }
  }
  final value = buffer.toString().trim();
  return value.isEmpty ? null : value;
}

String? _finishReasonFromResponse(Response response) {
  return switch (response.status) {
    ResponseStatus.completed => response.hasToolCalls ? 'tool_calls' : 'stop',
    ResponseStatus.failed => 'error',
    ResponseStatus.cancelled => 'cancelled',
    ResponseStatus.incomplete => 'length',
    ResponseStatus.queued ||
    ResponseStatus.inProgress ||
    ResponseStatus.unknown => null,
  };
}

LlmUsage? toLlmUsageFromResponseUsage(ResponseUsage? usage) {
  if (usage == null) {
    return null;
  }
  return LlmUsage(
    promptTokens: usage.inputTokens,
    completionTokens: usage.outputTokens,
    totalTokens: usage.totalTokens,
  );
}

/// Responses retrieve → 领域轮询结果。
LlmRemotePollResult toLlmRemotePollResult(Response response) {
  return switch (response.status) {
    ResponseStatus.queued || ResponseStatus.inProgress =>
      const LlmRemotePollResult(state: LlmRemotePollState.inProgress),
    ResponseStatus.completed => LlmRemotePollResult(
      state: LlmRemotePollState.completed,
      completion: toLlmChatCompletionFromResponse(response),
    ),
    ResponseStatus.failed => LlmRemotePollResult(
      state: LlmRemotePollState.failed,
      completion: toLlmChatCompletionFromResponse(response),
      errorMessage: response.error?.message,
    ),
    ResponseStatus.cancelled => LlmRemotePollResult(
      state: LlmRemotePollState.cancelled,
      completion: toLlmChatCompletionFromResponse(response),
    ),
    ResponseStatus.incomplete => LlmRemotePollResult(
      state: LlmRemotePollState.incomplete,
      completion: toLlmChatCompletionFromResponse(response),
    ),
    ResponseStatus.unknown => LlmRemotePollResult(
      state: LlmRemotePollState.failed,
      errorMessage: 'Unknown response status',
      completion: toLlmChatCompletionFromResponse(response),
    ),
  };
}

/// 将 Responses SSE 事件累加为 [LlmStreamSnapshot]。
class ResponsesStreamSnapshotAccumulator {
  String? _id;
  final StringBuffer _content = StringBuffer();
  final StringBuffer _reasoning = StringBuffer();
  final Map<int, _PendingFunctionCall> _toolCallsByIndex = {};
  String? _finishReason;
  LlmUsage? _usage;
  ResponseStatus _status = ResponseStatus.queued;

  String? get responseId => _id;

  bool get isTerminal =>
      _status == ResponseStatus.completed ||
      _status == ResponseStatus.failed ||
      _status == ResponseStatus.cancelled ||
      _status == ResponseStatus.incomplete;

  void add(ResponseStreamEvent event) {
    switch (event) {
      case ResponseCreatedEvent(:final response):
      case ResponseQueuedEvent(:final response):
      case ResponseInProgressEvent(:final response):
        _id = response.id;
        _status = response.status;
      case ResponseCompletedEvent(:final response):
      case ResponseFailedEvent(:final response):
      case ResponseIncompleteEvent(:final response):
        _applyFinalResponse(response);
      case OutputTextDeltaEvent(:final delta):
        _content.write(delta);
      case ReasoningTextDeltaEvent(:final delta):
        _reasoning.write(delta);
      case OutputItemAddedEvent(:final outputIndex, :final item):
        if (item is FunctionCallOutputItemResponse) {
          _toolCallsByIndex[outputIndex] = _PendingFunctionCall(
            id: item.callId,
            name: item.name,
            arguments: item.arguments,
          );
        }
      case OutputItemDoneEvent(:final outputIndex, :final item):
        if (item is FunctionCallOutputItemResponse) {
          _toolCallsByIndex[outputIndex] = _PendingFunctionCall(
            id: item.callId,
            name: item.name,
            arguments: item.arguments,
          );
        } else if (item is ReasoningItem) {
          for (final part in item.summary) {
            final text = part.text.trim();
            if (text.isNotEmpty) {
              if (_reasoning.isNotEmpty) {
                _reasoning.writeln();
              }
              _reasoning.write(text);
            }
          }
        }
      case FunctionCallArgumentsDeltaEvent(:final outputIndex, :final delta):
        final pending = _toolCallsByIndex.putIfAbsent(
          outputIndex,
          () => _PendingFunctionCall(id: '', name: '', arguments: ''),
        );
        pending.arguments += delta;
      case FunctionCallArgumentsDoneEvent(
        :final outputIndex,
        :final arguments,
        :final name,
      ):
        final pending = _toolCallsByIndex.putIfAbsent(
          outputIndex,
          () => _PendingFunctionCall(id: '', name: '', arguments: ''),
        );
        pending.arguments = arguments;
        if (name != null && name.isNotEmpty) {
          pending.name = name;
        }
      default:
        break;
    }
  }

  void _applyFinalResponse(Response response) {
    _id = response.id;
    _status = response.status;
    _usage = toLlmUsageFromResponseUsage(response.usage);
    _finishReason = _finishReasonFromResponse(response);
    if (_content.isEmpty && response.outputText.isNotEmpty) {
      _content.write(response.outputText);
    }
    if (response.functionCalls.isNotEmpty) {
      _toolCallsByIndex.clear();
      for (var i = 0; i < response.functionCalls.length; i++) {
        final call = response.functionCalls[i];
        _toolCallsByIndex[i] = _PendingFunctionCall(
          id: call.callId,
          name: call.name,
          arguments: call.arguments,
        );
      }
    }
  }

  LlmStreamSnapshot toSnapshot() {
    final toolCalls = [
      for (final entry
          in _toolCallsByIndex.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key)))
        if (entry.value.id.isNotEmpty || entry.value.name.isNotEmpty)
          LlmToolCall(
            id: entry.value.id.isEmpty ? 'call_${entry.key}' : entry.value.id,
            name: entry.value.name,
            arguments: entry.value.arguments,
          ),
    ];
    final reasoning = _reasoning.toString();
    return LlmStreamSnapshot(
      id: _id,
      content: _content.toString(),
      finishReason: _finishReason,
      usage: _usage,
      toolCalls: toolCalls,
      reasoningContent: reasoning,
      reasoning: reasoning,
    );
  }
}

class _PendingFunctionCall {
  _PendingFunctionCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  String id;
  String name;
  String arguments;
}
