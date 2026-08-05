part of 'chat_service.dart';

/// assistant turn、消息片段与用量映射。
mixin _ChatAssistantTurnMapper on _ChatServiceHelpers {
  List<ChatMessagePart> _seedCommittedParts(
    ChatConversationMessage? resumeAssistant,
  ) {
    final parts = resumeAssistant?.parts ?? const <ChatMessagePart>[];
    return [
      for (final part in parts)
        if (part is ChatToolCallPart &&
            part.status == ChatToolCallPartStatus.running)
          part.copyWith(
            status: ChatToolCallPartStatus.failed,
            result: jsonEncode({
              'error': 'cancelled',
              'message': t.main.input.stop,
            }),
          )
        else
          part,
    ];
  }

  /// 取回同一 remote response 时，去掉末尾未完成的正文/推理，避免与 retrieve 结果重复。
  List<ChatMessagePart> _seedPartsForRemoteResume(
    ChatConversationMessage? resumeAssistant,
  ) {
    final seeded = _seedCommittedParts(resumeAssistant);
    var end = seeded.length;
    while (end > 0) {
      final part = seeded[end - 1];
      if (part is ChatTextPart || part is ChatReasoningPart) {
        end -= 1;
        continue;
      }
      break;
    }
    return seeded.sublist(0, end);
  }

  int _nextRoundIndex(List<ChatMessagePart> parts) {
    var count = 0;
    for (final part in parts) {
      if (part is ChatReasoningPart || part is ChatTextPart) {
        count += 1;
      }
    }
    return count;
  }

  ChatConversationMessage _buildAssistantTurn({
    required String turnId,
    required ChatConversationMessage? current,
    required List<ChatMessagePart> parts,
    String? finishReason,
    String? completionId,
    ChatUsageSnapshot? usage,
  }) {
    final content = _joinTextParts(parts);
    if (current == null) {
      return ChatConversationMessage(
        id: turnId,
        role: ChatConversationRole.assistant,
        content: content,
        createdAt: DateTime.now(),
        finishReason: finishReason,
        completionId: completionId,
        usage: usage,
        parts: parts,
        isInterrupted: false,
      ).withSyncedSingleVersion();
    }

    final updated = current
        .copyWith(
          content: content,
          finishReason: finishReason,
          completionId: completionId,
          usage: usage,
          parts: parts,
          isInterrupted: false,
        )
        .withUpdatedSelectedVersion();
    // 本轮 completion 已到手时清空进行中的 remoteResponseId；下一轮 create 会再写入。
    if (finishReason != null) {
      return updated
          .copyWith(remoteResponseId: null)
          .withUpdatedSelectedVersion();
    }
    return updated;
  }

  List<ChatMessagePart> _partsFromCompletion({
    required LlmChatCompletion response,
    required String turnId,
    required int round,
    required bool allowEmptyText,
  }) {
    final parts = <ChatMessagePart>[];
    final reasoning = _resolveAssistantReasoning(response);
    if (reasoning != null && reasoning.isNotEmpty) {
      parts.add(ChatReasoningPart(id: '${turnId}_r$round', content: reasoning));
    }

    final text = _resolveAssistantText(response, allowEmpty: allowEmptyText);
    if (text.isNotEmpty) {
      parts.add(ChatTextPart(id: '${turnId}_t$round', content: text));
    }
    return parts;
  }

  List<ChatMessagePart> _partsFromStreamSnapshot({
    required LlmStreamSnapshot snapshot,
    required String turnId,
    required int round,
    required bool allowEmptyText,
  }) {
    final parts = <ChatMessagePart>[];
    final reasoning = _resolveStreamingAssistantReasoning(snapshot);
    if (reasoning != null && reasoning.isNotEmpty) {
      parts.add(ChatReasoningPart(id: '${turnId}_r$round', content: reasoning));
    }

    final text = _resolveStreamingAssistantText(
      snapshot,
      allowEmptyWhenToolCalls: allowEmptyText,
    );
    if (text.isNotEmpty) {
      parts.add(ChatTextPart(id: '${turnId}_t$round', content: text));
    }
    return parts;
  }

  String _joinTextParts(List<ChatMessagePart> parts) {
    return [
      for (final part in parts)
        if (part is ChatTextPart && part.content.trim().isNotEmpty)
          part.content,
    ].join('\n\n');
  }

  ChatUsageSnapshot? _resolveUsage(LlmUsage? usage) {
    return usage == null
        ? null
        : ChatUsageSnapshot(
            promptTokens: usage.promptTokens,
            completionTokens: usage.completionTokens,
            totalTokens: usage.totalTokens,
          );
  }

  String? _encodeToolArguments(LlmToolCall toolCall) {
    final raw = toolCall.arguments.trim();
    return raw.isEmpty ? null : raw;
  }

  Map<String, dynamic> _readToolArguments(LlmToolCall toolCall) {
    try {
      return toolCall.argumentsMap;
    } catch (error) {
      Log.w(
        'Chat tool arguments parse failed: name=${toolCall.name}, '
        'error=$error',
        tag: 'Chat',
      );
      return const {};
    }
  }

  String _resolveAssistantText(
    LlmChatCompletion response, {
    required bool allowEmpty,
  }) {
    final refusal = response.refusal?.trim();
    if (refusal != null && refusal.isNotEmpty) {
      return refusal;
    }

    final text = response.text?.trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }

    if (allowEmpty) {
      return '';
    }

    return t.chat.error.emptyAssistantResponse;
  }

  String? _resolveAssistantReasoning(LlmChatCompletion response) {
    final message = response.message;
    if (message == null) {
      return null;
    }

    return _firstNotEmpty([
      message.reasoningContent,
      message.reasoning,
      ...?message.reasoningDetails,
    ]);
  }

  String _resolveStreamingAssistantText(
    LlmStreamSnapshot snapshot, {
    required bool allowEmptyWhenToolCalls,
  }) {
    final refusal = snapshot.refusal.trim();
    if (refusal.isNotEmpty) {
      return refusal;
    }

    final text = snapshot.content;
    if (text.trim().isNotEmpty || snapshot.finishReason == null) {
      return text;
    }

    if (allowEmptyWhenToolCalls) {
      return '';
    }

    return t.chat.error.emptyAssistantResponse;
  }

  String? _resolveStreamingAssistantReasoning(LlmStreamSnapshot snapshot) {
    return _firstNotEmpty([
      snapshot.reasoningContent,
      snapshot.reasoning,
      ...snapshot.reasoningDetailTexts,
    ]);
  }

  String? _firstNotEmpty(Iterable<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  String _createTurnId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
