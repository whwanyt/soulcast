part of 'chat.dart';

/// Chat notifier 的当前会话内容清理。
mixin _ChatConversationClearActions on _ChatConversationManagementActions {
  void clear() {
    Log.d('Chat state cleared: messages=${state.messages.length}', tag: 'Chat');
    _abortRequest();
    final conversationId = state.selectedConversationId;
    if (conversationId != null) {
      unawaited(_clearStoredMessages(conversationId));
      unawaited(_saveDraftMessage(conversationId, ''));
    }
    state = state.copyWith(
      messages: const [],
      draftMessage: '',
      draftAttachments: const [],
      isSending: false,
      errorMessage: null,
      lastUsage: null,
    );
  }

  Future<void> clearConversationMessages(String conversationId) async {
    final isSelectedConversation =
        state.selectedConversationId == conversationId;
    if (isSelectedConversation) {
      _abortRequest();
    }

    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.clearMessages(conversationId);
      repository.saveDraftMessage(
        conversationId: conversationId,
        draftMessage: '',
      );
      Log.d(
        'Chat conversation messages cleared: conversationId=$conversationId',
        tag: 'Chat',
      );
      if (!isSelectedConversation) {
        return;
      }
      state = state.clearedConversationMessages(conversationId);
    } catch (error, stackTrace) {
      Log.e(
        'Chat conversation messages clear failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      if (isSelectedConversation) {
        state = state.copyWith(
          isSending: false,
          errorMessage: error.toString(),
        );
      }
    }
  }
}
