part of 'chat.dart';

/// Chat notifier 的会话模型与输入草稿设置。
mixin _ChatConversationSettingsActions on _ChatConversationCreationActions {
  Future<void> setConversationModel(String modelId) async {
    if (state.selectedModelId == modelId) {
      return;
    }

    final conversationId = await _ensureSelectedConversationId();
    if (conversationId == null) {
      return;
    }

    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.saveConversationModel(
        conversationId: conversationId,
        modelId: modelId,
      );
      Log.d(
        'Chat conversation model selected: '
        'conversationId=$conversationId, modelId=$modelId',
        tag: 'Chat',
      );
      state = state.copyWith(selectedModelId: modelId, errorMessage: null);
    } catch (error, stackTrace) {
      Log.e(
        'Chat conversation model select failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> updateDraftMessage(String draftMessage) async {
    if (state.draftMessage == draftMessage) {
      return;
    }

    state = state.copyWith(draftMessage: draftMessage);
    final conversationId = state.selectedConversationId;
    if (conversationId == null) {
      return;
    }

    await _saveDraftMessage(conversationId, draftMessage);
  }
}
