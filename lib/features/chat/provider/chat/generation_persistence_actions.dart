part of 'chat.dart';

/// Chat notifier 的生成快照、完成结果与中断状态持久化。
mixin _ChatGenerationPersistenceActions on _ChatGenerationFailureActions {
  void _applyFocusedMessages({
    required String conversationId,
    required List<ChatConversationMessage> messages,
    ChatUsageSnapshot? lastUsage,
    bool? isSending,
  }) {
    if (!_isConversationFocused(conversationId)) {
      return;
    }
    state = state.copyWith(
      messages: messages,
      errorMessage: null,
      lastUsage: lastUsage,
      isSending: isSending,
    );
  }

  Future<void> _maybeCheckpointAssistant({
    required String conversationId,
    required List<ChatConversationMessage> assistantMessages,
    required bool force,
  }) async {
    if (assistantMessages.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final last = _lastStreamCheckpointAt;
    if (!force &&
        last != null &&
        now.difference(last) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastStreamCheckpointAt = now;
    await _saveMessages(conversationId, assistantMessages);
  }

  Future<void> _checkpointRemoteResponseId({
    required String conversationId,
    required String remoteResponseId,
  }) async {
    final trimmed = remoteResponseId.trim();
    if (trimmed.isEmpty || _activeRunConversationId != conversationId) {
      return;
    }

    final messages = _isConversationFocused(conversationId)
        ? state.messages
        : const <ChatConversationMessage>[];
    final last = messages.isNotEmpty ? messages.last : null;
    final target =
        (last != null &&
            last.role == ChatConversationRole.assistant &&
            last.id == (_activePlaceholderAssistant?.id ?? last.id))
        ? last
        : _activePlaceholderAssistant;
    if (target == null || target.role != ChatConversationRole.assistant) {
      return;
    }
    if (target.remoteResponseId == trimmed) {
      return;
    }

    final updated = target
        .copyWith(remoteResponseId: trimmed)
        .withUpdatedSelectedVersion();
    if (_activePlaceholderAssistant?.id == updated.id) {
      _activePlaceholderAssistant = updated;
    }
    await _saveMessages(conversationId, [updated]);
    if (_isConversationFocused(conversationId) &&
        messages.isNotEmpty &&
        messages.last.id == updated.id) {
      state = state.copyWith(
        messages: [...messages.sublist(0, messages.length - 1), updated],
      );
    }
    Log.d(
      'Chat remoteResponseId checkpointed: messageId=${updated.id}, '
      'remoteResponseId=$trimmed',
      tag: 'Chat',
    );
  }

  List<ChatConversationMessage> _prefixWithoutResumeAssistant(
    List<ChatConversationMessage> prefixMessages,
    ChatConversationMessage? resumeAssistant,
  ) {
    if (resumeAssistant == null || prefixMessages.isEmpty) {
      return prefixMessages;
    }
    final last = prefixMessages.last;
    if (last.id == resumeAssistant.id) {
      return prefixMessages.sublist(0, prefixMessages.length - 1);
    }
    return prefixMessages;
  }

  Future<void> _finishSuccessfulCompletion({
    required String conversationId,
    required LlmClient client,
    required ChatSettings settings,
    required ChatConversationMemory memory,
    required ChatConversationMessage userMessage,
    required List<ChatConversationMessage> prefixMessages,
    required ChatCompletionResult completionResult,
    _AssistantRegenerateContext? regenerate,
    ChatConversationMessage? resumeAssistant,
  }) async {
    final projected = _projectCompletionResult(
      completionResult,
      regenerate: regenerate,
      resumeAssistant: resumeAssistant,
    );
    final finalizedMessages = [
      for (final message in projected.messages)
        if (message.role == ChatConversationRole.assistant)
          message
              .copyWith(
                finishReason: message.finishReason ?? 'stop',
                remoteResponseId: null,
              )
              .withUpdatedSelectedVersion()
        else
          message,
    ];
    final finalized = ChatCompletionResult(
      messages: finalizedMessages,
      isToolCallsExceeded: projected.isToolCallsExceeded,
    );
    _logCompletionSucceeded(finalized);
    await _saveMessages(conversationId, finalized.messages);
    _applyFocusedMessages(
      conversationId: conversationId,
      messages: [...prefixMessages, ...finalized.messages],
      isSending: false,
      lastUsage: finalized.lastUsage,
    );
    if (!_isConversationFocused(conversationId) &&
        state.isSending &&
        _activeRunConversationId == conversationId) {
      // 理论上切走时已清 isSending；兜底避免卡在发送中。
      state = state.copyWith(isSending: false);
    }
    await _updateMemoryAfterCompletion(
      client: client,
      settings: settings,
      conversationId: conversationId,
      memory: memory,
      userMessage: userMessage,
      completionResult: finalized,
    );
    await _updateTitleAfterCompletion(
      client: client,
      settings: settings,
      conversationId: conversationId,
      userMessage: userMessage,
      completionResult: finalized,
    );
  }

  @override
  Future<void> _persistInterruptedAssistant(
    String conversationId, {
    List<ChatConversationMessage>? sourceMessages,
  }) async {
    final messages =
        sourceMessages ??
        (_isConversationFocused(conversationId)
            ? state.messages
            : const <ChatConversationMessage>[]);
    if (messages.isEmpty) {
      if (_isConversationFocused(conversationId)) {
        state = state.copyWith(isSending: false, errorMessage: null);
      }
      return;
    }

    final last = messages.last;
    if (last.role != ChatConversationRole.assistant) {
      final regenerate = _activeRegenerate;
      if (regenerate != null && regenerate.existingVersions.isNotEmpty) {
        final restored = _assistantFromVersions(
          turnId: regenerate.turnId,
          createdAt: regenerate.createdAt,
          versions: regenerate.existingVersions,
          selectedVersionIndex: regenerate.existingVersions.length - 1,
        );
        await _saveMessages(conversationId, [restored]);
        if (_isConversationFocused(conversationId)) {
          state = state.copyWith(
            isSending: false,
            errorMessage: null,
            messages: [...messages, restored],
          );
        }
        return;
      }
      if (_isConversationFocused(conversationId)) {
        state = state.copyWith(isSending: false, errorMessage: null);
      }
      return;
    }

    final hasVisibleContent =
        last.content.trim().isNotEmpty || last.parts.isNotEmpty;
    if (!hasVisibleContent) {
      final regenerate = _activeRegenerate;
      if (regenerate != null && regenerate.existingVersions.isNotEmpty) {
        final restored = _assistantFromVersions(
          turnId: regenerate.turnId,
          createdAt: regenerate.createdAt,
          versions: regenerate.existingVersions,
          selectedVersionIndex: regenerate.existingVersions.length - 1,
        );
        await _saveMessages(conversationId, [restored]);
        if (_isConversationFocused(conversationId)) {
          state = state.copyWith(
            isSending: false,
            errorMessage: null,
            messages: [...messages.sublist(0, messages.length - 1), restored],
          );
        }
        return;
      }
      // 保留空占位助手并标中断，避免只剩用户消息。
      final interrupted = last
          .copyWith(isInterrupted: true, remoteResponseId: null)
          .withUpdatedSelectedVersion();
      await _saveMessages(conversationId, [interrupted]);
      if (_isConversationFocused(conversationId)) {
        state = state.copyWith(
          isSending: false,
          errorMessage: null,
          messages: [...messages.sublist(0, messages.length - 1), interrupted],
        );
      }
      Log.d(
        'Chat empty placeholder interrupted: messageId=${interrupted.id}',
        tag: 'Chat',
      );
      return;
    }

    final interrupted = last
        .copyWith(
          isInterrupted: true,
          remoteResponseId: null,
          parts: [
            for (final part in last.parts)
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
          ],
        )
        .withUpdatedSelectedVersion();
    await _saveMessages(conversationId, [interrupted]);
    if (_isConversationFocused(conversationId)) {
      state = state.copyWith(
        isSending: false,
        errorMessage: null,
        messages: [...messages.sublist(0, messages.length - 1), interrupted],
      );
    }
    Log.d(
      'Chat interrupted assistant persisted: messageId=${interrupted.id}',
      tag: 'Chat',
    );
  }
}
