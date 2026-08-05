part of 'chat.dart';

/// Chat notifier 的完成结果投影、消息版本合并与成功日志。
mixin _ChatGenerationProjection on _ChatSendActions {
  ChatCompletionResult _projectCompletionResult(
    ChatCompletionResult completionResult, {
    _AssistantRegenerateContext? regenerate,
    ChatConversationMessage? resumeAssistant,
  }) {
    return ChatCompletionResult(
      messages: [
        for (final message in completionResult.messages)
          if (message.role == ChatConversationRole.assistant)
            _projectAssistantCompletion(
              generated: message,
              regenerate: regenerate,
              resumeAssistant: resumeAssistant,
            )
          else
            message,
      ],
      isToolCallsExceeded: completionResult.isToolCallsExceeded,
    );
  }

  ChatConversationMessage _projectAssistantCompletion({
    required ChatConversationMessage generated,
    _AssistantRegenerateContext? regenerate,
    ChatConversationMessage? resumeAssistant,
  }) {
    if (regenerate != null) {
      final newVersion = ChatAssistantMessageVersion(
        id: generated.id,
        content: generated.content,
        createdAt: generated.createdAt,
        finishReason: generated.finishReason,
        completionId: generated.completionId,
        remoteResponseId: generated.finishReason != null
            ? null
            : generated.remoteResponseId,
        usage: generated.usage,
        parts: generated.parts,
        isInterrupted: generated.isInterrupted,
      );
      final versions = [...regenerate.existingVersions, newVersion];
      return ChatConversationMessage(
        id: regenerate.turnId,
        role: ChatConversationRole.assistant,
        content: newVersion.content,
        createdAt: regenerate.createdAt,
        finishReason: newVersion.finishReason,
        completionId: newVersion.completionId,
        remoteResponseId: newVersion.remoteResponseId,
        usage: newVersion.usage,
        parts: newVersion.parts,
        isInterrupted: newVersion.isInterrupted,
        versions: versions,
        selectedVersionIndex: versions.length - 1,
      );
    }

    if (resumeAssistant != null) {
      return _mergeGeneratedAssistant(
        base: resumeAssistant,
        generated: generated,
      );
    }

    final placeholder = _activePlaceholderAssistant;
    if (placeholder != null) {
      return _mergeGeneratedAssistant(base: placeholder, generated: generated);
    }

    if (generated.versions.isEmpty) {
      return generated.withSyncedSingleVersion();
    }
    return generated.withUpdatedSelectedVersion();
  }

  /// 合并生成快照到占位/续写消息，避免冲掉已 checkpoint 的 remoteResponseId。
  ChatConversationMessage _mergeGeneratedAssistant({
    required ChatConversationMessage base,
    required ChatConversationMessage generated,
  }) {
    var next = base.copyWith(
      content: generated.content,
      finishReason: generated.finishReason,
      completionId: generated.completionId,
      usage: generated.usage,
      parts: generated.parts,
      isInterrupted: generated.isInterrupted,
    );
    if (generated.finishReason != null) {
      next = next.copyWith(remoteResponseId: null);
    } else {
      final remoteResponseId = generated.remoteResponseId?.trim();
      if (remoteResponseId != null && remoteResponseId.isNotEmpty) {
        next = next.copyWith(remoteResponseId: remoteResponseId);
      }
    }
    return next.withUpdatedSelectedVersion();
  }

  void _logCompletionSucceeded(ChatCompletionResult completionResult) {
    final assistantMessage = completionResult.lastAssistantMessage;
    Log.d(
      'Chat send succeeded: messages=${completionResult.messages.length}, '
      'completionId=${assistantMessage?.completionId}, '
      'finishReason=${assistantMessage?.finishReason}, '
      'replyLength=${assistantMessage?.content.length}, '
      'totalTokens=${completionResult.lastUsage?.totalTokens}',
      tag: 'Chat',
    );
  }
}
