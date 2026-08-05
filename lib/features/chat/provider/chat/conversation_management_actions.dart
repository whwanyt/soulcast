part of 'chat.dart';

/// Chat notifier 的会话置顶、重命名与删除。
mixin _ChatConversationManagementActions on _ChatConversationSettingsActions {
  Future<void> setConversationPinned({
    required String conversationId,
    required bool isPinned,
  }) async {
    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.setConversationPinned(
        conversationId: conversationId,
        isPinned: isPinned,
      );
      Log.d(
        'Chat conversation pin changed: '
        'conversationId=$conversationId, isPinned=$isPinned',
        tag: 'Chat',
      );
    } catch (error, stackTrace) {
      Log.e(
        'Chat conversation pin failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> renameConversation({
    required String conversationId,
    required String title,
  }) async {
    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      final renamed = repository.renameConversation(
        conversationId: conversationId,
        title: title,
      );
      Log.d(
        'Chat conversation rename ${renamed ? 'saved' : 'skipped'}: '
        'conversationId=$conversationId',
        tag: 'Chat',
      );
    } catch (error, stackTrace) {
      Log.e(
        'Chat conversation rename failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    _abortRequest();
    final loadSerial = ++_loadSerial;

    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      final wasSelected = state.selectedConversationId == conversationId;
      final deleted = repository.deleteConversation(conversationId);
      if (!deleted) {
        return;
      }

      if (!wasSelected) {
        Log.d(
          'Chat conversation deleted: conversationId=$conversationId',
          tag: 'Chat',
        );
        return;
      }

      final conversations = repository.getConversations();
      final nextConversation = conversations.isEmpty
          ? repository.ensureConversation()
          : conversations.first;
      final messages = repository.getMessages(nextConversation.id);
      final reconciled = await _loadAndReconcileMessages(
        conversationId: nextConversation.id,
        messages: messages,
      );
      await _saveSelectedConversation(nextConversation.id);
      if (loadSerial != _loadSerial) {
        return;
      }

      state = state.copyWith(
        selectedConversationId: nextConversation.id,
        selectedModelId: nextConversation.modelId,
        messages: reconciled,
        draftMessage: nextConversation.draftMessage,
        isLoadingMessages: false,
        isSending: false,
        errorMessage: null,
        lastUsage: null,
      );
      unawaited(resumePendingRemoteResponse());
      Log.d(
        'Chat selected conversation deleted: '
        'deletedConversationId=$conversationId, '
        'nextConversationId=${nextConversation.id}',
        tag: 'Chat',
      );
    } catch (error, stackTrace) {
      if (loadSerial != _loadSerial) {
        return;
      }
      Log.e(
        'Chat conversation delete failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoadingMessages: false,
        isSending: false,
        errorMessage: error.toString(),
      );
    }
  }
}
