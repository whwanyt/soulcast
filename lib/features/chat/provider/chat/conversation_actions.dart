part of 'chat.dart';

/// Chat notifier 的会话恢复、选择与消息协调。
mixin _ChatConversationActions on _ChatController {
  Future<void> restoreInitialConversation({bool force = false}) async {
    if (!force && state.selectedConversationId != null) {
      return;
    }

    if (force) {
      _abortRequest();
      state = state.copyWith(
        selectedConversationId: null,
        selectedModelId: null,
        messages: const [],
        draftMessage: '',
        draftAttachments: const [],
        isLoadingMessages: true,
        isSending: false,
        errorMessage: null,
        lastUsage: null,
      );
    }

    final loadSerial = ++_loadSerial;
    state = state.copyWith(isLoadingMessages: true, errorMessage: null);
    try {
      await ref.read(appPreferencesProvider.notifier).restore();
      await ref.read(agentToolConfigsProvider.notifier).restore();
      final repository = await ref.read(chatRepositoryProvider.future);
      final preferences = ref.read(appPreferencesProvider);
      final conversations = repository.getConversations();
      final savedConversation = preferences.selectedConversationId == null
          ? null
          : repository.getConversation(preferences.selectedConversationId!);
      final conversation =
          savedConversation ??
          (conversations.isEmpty
              ? repository.ensureConversation()
              : conversations.first);
      final rawMessages = repository.getMessages(conversation.id);
      final messages = await _loadAndReconcileMessages(
        conversationId: conversation.id,
        messages: rawMessages,
      );
      await _saveSelectedConversation(conversation.id);
      if (loadSerial != _loadSerial) {
        return;
      }
      Log.d(
        'Chat initial conversation restored: '
        'conversationId=${conversation.id}, messages=${messages.length}',
        tag: 'Chat',
      );
      state = state.copyWith(
        selectedConversationId: conversation.id,
        selectedModelId: conversation.modelId,
        messages: messages,
        draftMessage: conversation.draftMessage,
        isLoadingMessages: false,
        errorMessage: null,
      );
      unawaited(resumePendingRemoteResponse());
    } catch (error, stackTrace) {
      if (loadSerial != _loadSerial) {
        return;
      }
      Log.e(
        'Chat initial conversation restore failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoadingMessages: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> selectConversation(String conversationId) async {
    if (state.selectedConversationId == conversationId) {
      return;
    }

    final previousId = state.selectedConversationId;
    final wasSending = state.isSending;
    final snapshot = List<ChatConversationMessage>.from(state.messages);

    // 先落盘旧会话中断态，再 abort / 清空 UI，避免 persist 读到空列表。
    if (wasSending && previousId != null) {
      await _persistInterruptedAssistant(previousId, sourceMessages: snapshot);
    }
    _abortRequest();

    final loadSerial = ++_loadSerial;
    state = state.copyWith(
      selectedConversationId: conversationId,
      selectedModelId: null,
      messages: const [],
      draftMessage: '',
      draftAttachments: const [],
      isLoadingMessages: true,
      isSending: false,
      errorMessage: null,
      lastUsage: null,
    );

    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      final conversation = repository.ensureConversation(
        conversationId: conversationId,
      );
      final rawMessages = repository.getMessages(conversationId);
      final messages = await _loadAndReconcileMessages(
        conversationId: conversationId,
        messages: rawMessages,
      );
      await _saveSelectedConversation(conversationId);
      if (loadSerial != _loadSerial) {
        return;
      }
      Log.d(
        'Chat conversation selected: '
        'conversationId=$conversationId, messages=${messages.length}',
        tag: 'Chat',
      );
      state = state.copyWith(
        messages: messages,
        selectedModelId: conversation.modelId,
        draftMessage: conversation.draftMessage,
        isLoadingMessages: false,
        errorMessage: null,
      );
      unawaited(resumePendingRemoteResponse());
    } catch (error, stackTrace) {
      if (loadSerial != _loadSerial) {
        return;
      }
      Log.e(
        'Chat conversation select failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoadingMessages: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<List<ChatConversationMessage>> _loadAndReconcileMessages({
    required String conversationId,
    required List<ChatConversationMessage> messages,
  }) async {
    final reconciled = _reconcileLoadedMessages(messages);
    if (!identical(reconciled, messages) && reconciled.isNotEmpty) {
      final changed = <ChatConversationMessage>[];
      for (var i = 0; i < reconciled.length; i++) {
        if (i >= messages.length ||
            reconciled[i].streamFingerprint != messages[i].streamFingerprint) {
          changed.add(reconciled[i]);
        }
      }
      if (changed.isNotEmpty) {
        await _saveMessages(conversationId, changed);
      }
    }
    return reconciled;
  }
}
