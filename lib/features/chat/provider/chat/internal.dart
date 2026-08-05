part of 'chat.dart';

/// Chat notifier 的请求中止、懒创建会话与持久化内部能力。
mixin _ChatInternal on _ChatController {
  @override
  void _abortRequest() {
    final abortCompleter = _abortCompleter;
    if (abortCompleter == null || abortCompleter.isCompleted) {
      return;
    }
    Log.d('Chat request aborting', tag: 'Chat');
    abortCompleter.complete();
    _abortCompleter = null;
  }

  @override
  bool _isConversationFocused(String conversationId) {
    return state.selectedConversationId == conversationId;
  }

  /// 冷启动/切回后：未收尾的末条助手标为中断，避免假装仍在生成。
  @override
  List<ChatConversationMessage> _reconcileLoadedMessages(
    List<ChatConversationMessage> messages,
  ) {
    if (messages.isEmpty) {
      return messages;
    }

    var lastIndex = messages.length - 1;
    while (lastIndex >= 0 &&
        messages[lastIndex].role == ChatConversationRole.memory) {
      lastIndex -= 1;
    }
    if (lastIndex < 0) {
      return messages;
    }

    final last = messages[lastIndex];
    if (last.role != ChatConversationRole.assistant || last.isInterrupted) {
      return messages;
    }

    // 无 finishReason 视为生成未正常收尾（占位或 checkpoint 后进程被杀）。
    if (last.finishReason != null) {
      return messages;
    }

    // Responses background：有可取回 id 时交给 resume，不标 interrupted。
    final remoteResponseId = last.remoteResponseId?.trim();
    if (remoteResponseId != null && remoteResponseId.isNotEmpty) {
      return messages;
    }

    final interrupted = last
        .copyWith(isInterrupted: true)
        .withUpdatedSelectedVersion();
    return [
      ...messages.sublist(0, lastIndex),
      interrupted,
      ...messages.sublist(lastIndex + 1),
    ];
  }

  @override
  Future<String?> _ensureSelectedConversationId() async {
    final selectedConversationId = state.selectedConversationId;
    if (selectedConversationId != null) {
      return selectedConversationId;
    }

    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      final conversation = repository.ensureConversation();
      state = state.copyWith(selectedConversationId: conversation.id);
      await _saveSelectedConversation(conversation.id);
      return conversation.id;
    } catch (error, stackTrace) {
      Log.e(
        'Chat conversation ensure failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: error.toString());
      return null;
    }
  }

  @override
  Future<void> _saveMessages(
    String conversationId,
    List<ChatConversationMessage> messages,
  ) async {
    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.saveMessages(
        conversationId: conversationId,
        messages: messages,
      );
    } catch (error, stackTrace) {
      Log.e(
        'Chat messages persist failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  @override
  Future<void> _clearStoredMessages(String conversationId) async {
    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.clearMessages(conversationId);
    } catch (error, stackTrace) {
      Log.e(
        'Chat messages clear failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  @override
  Future<void> _deleteStoredMessages({
    required String conversationId,
    required List<String> ids,
  }) async {
    if (ids.isEmpty) {
      return;
    }
    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.deleteMessages(conversationId: conversationId, ids: ids);
    } catch (error, stackTrace) {
      Log.e(
        'Chat messages delete failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  @override
  Future<void> _saveDraftMessage(
    String conversationId,
    String draftMessage,
  ) async {
    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.saveDraftMessage(
        conversationId: conversationId,
        draftMessage: draftMessage,
      );
    } catch (error, stackTrace) {
      Log.e(
        'Chat draft persist failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  @override
  Future<void> _saveSelectedConversation(String conversationId) {
    return ref
        .read(appPreferencesProvider.notifier)
        .selectConversation(conversationId);
  }
}
