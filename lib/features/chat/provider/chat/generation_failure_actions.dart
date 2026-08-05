part of 'chat.dart';

/// Chat notifier 的生成失败呈现与错误消息构造。
mixin _ChatGenerationFailureActions on _ChatGenerationProjection {
  Future<void> _presentGenerationFailure({
    required String conversationId,
    required String errorMessage,
  }) async {
    final regenerate = _activeRegenerate;
    if (regenerate != null && regenerate.existingVersions.isNotEmpty) {
      await _restoreRegenerateTurnOnFailure(
        conversationId: conversationId,
        errorMessage: errorMessage,
      );
      return;
    }

    final messages = _isConversationFocused(conversationId)
        ? state.messages
        : const <ChatConversationMessage>[];
    final last = messages.isNotEmpty ? messages.last : null;
    final existingAssistant = last?.role == ChatConversationRole.assistant
        ? last
        : _activePlaceholderAssistant;
    final errorAssistant = _assistantMessageForError(
      existing: existingAssistant,
      turnId: regenerate?.turnId ?? _activePlaceholderAssistant?.id,
      createdAt:
          regenerate?.createdAt ?? _activePlaceholderAssistant?.createdAt,
      errorMessage: errorMessage,
    );
    await _saveMessages(conversationId, [errorAssistant]);
    if (_isConversationFocused(conversationId)) {
      final nextMessages =
          existingAssistant != null &&
              messages.isNotEmpty &&
              messages.last.id == existingAssistant.id
          ? [...messages.sublist(0, messages.length - 1), errorAssistant]
          : [...messages, errorAssistant];
      state = state.copyWith(
        isSending: false,
        errorMessage: errorMessage,
        messages: nextMessages,
      );
    } else {
      state = state.copyWith(isSending: false, errorMessage: errorMessage);
    }
  }

  ChatConversationMessage _assistantMessageForError({
    ChatConversationMessage? existing,
    String? turnId,
    DateTime? createdAt,
    required String errorMessage,
  }) {
    if (existing != null) {
      final hasVisibleContent =
          existing.content.trim().isNotEmpty || existing.parts.isNotEmpty;
      if (!hasVisibleContent) {
        return existing
            .copyWith(
              content: errorMessage,
              parts: [
                ChatTextPart(id: '${existing.id}-text', content: errorMessage),
              ],
              isInterrupted: false,
              finishReason: 'error',
              remoteResponseId: null,
            )
            .withUpdatedSelectedVersion();
      }

      final errorPart = ChatTextPart(
        id: '${existing.id}-error-${DateTime.now().microsecondsSinceEpoch}',
        content: errorMessage,
      );
      final nextContent = existing.content.trim().isEmpty
          ? errorMessage
          : '${existing.content}\n\n$errorMessage';
      return existing
          .copyWith(
            content: nextContent,
            parts: [...existing.parts, errorPart],
            isInterrupted: false,
            finishReason: 'error',
            remoteResponseId: null,
          )
          .withUpdatedSelectedVersion();
    }

    if (turnId != null) {
      final message = ChatConversationMessage(
        id: turnId,
        role: ChatConversationRole.assistant,
        content: errorMessage,
        createdAt: createdAt ?? DateTime.now(),
        finishReason: 'error',
        parts: [ChatTextPart(id: '$turnId-text', content: errorMessage)],
      );
      return message.withSyncedSingleVersion();
    }

    return ChatConversationMessage.assistant(content: errorMessage);
  }
}
