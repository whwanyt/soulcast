part of 'chat.dart';

/// Chat notifier 的助手回复重新生成与版本切换能力。
mixin _ChatRegenerateActions on _ChatController {
  Future<void> regenerateLastAssistant() async {
    if (state.isSending) {
      Log.d('Skip regenerate because another request is active', tag: 'Chat');
      return;
    }

    _clearErrorMessage();
    if (state.selectedModelId == null) {
      state = state.copyWith(errorMessage: t.chat.error.missingModel);
      return;
    }

    final conversationId = state.selectedConversationId;
    if (conversationId == null) {
      return;
    }

    final turn = _resolveLastAssistantTurn(state.messages);
    if (turn == null) {
      Log.d('Skip regenerate: missing last assistant turn', tag: 'Chat');
      return;
    }

    final trailingMemoryIds = [
      for (
        var index = turn.assistantIndex + 1;
        index < state.messages.length;
        index++
      )
        if (state.messages[index].role == ChatConversationRole.memory)
          state.messages[index].id,
    ];
    if (trailingMemoryIds.isNotEmpty) {
      await _deleteStoredMessages(
        conversationId: conversationId,
        ids: trailingMemoryIds,
      );
    }

    final assistant = turn.assistant.versions.isEmpty
        ? turn.assistant.withSyncedSingleVersion()
        : turn.assistant;
    final hasVisibleContent =
        assistant.content.trim().isNotEmpty || assistant.parts.isNotEmpty;
    final existingVersions = hasVisibleContent
        ? assistant.versions
        : const <ChatAssistantMessageVersion>[];
    final prefixMessages = state.messages.sublist(0, turn.userIndex + 1);

    Log.d(
      'Chat regenerate started: turnId=${assistant.id}, '
      'existingVersions=${existingVersions.length}',
      tag: 'Chat',
    );
    state = state.copyWith(messages: prefixMessages, errorMessage: null);

    await _runAssistantGeneration(
      conversationId: conversationId,
      prefixMessages: prefixMessages,
      userMessage: turn.userMessage,
      resumeAssistant: null,
      continueUserPrompt: null,
      regenerate: _AssistantRegenerateContext(
        turnId: assistant.id,
        existingVersions: existingVersions,
        createdAt: assistant.createdAt,
      ),
    );
  }

  Future<void> selectAssistantVersion({
    required String messageId,
    required int index,
  }) async {
    final assistantIndex = state.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (assistantIndex < 0) {
      return;
    }

    final assistant = state.messages[assistantIndex];
    if (assistant.role != ChatConversationRole.assistant ||
        !assistant.hasMultipleVersions) {
      return;
    }

    // 正在生成的同一条助手消息不允许切换版本。
    if (state.isSending) {
      final activeTurn = _resolveLastAssistantTurn(state.messages);
      if (activeTurn != null && activeTurn.assistant.id == messageId) {
        return;
      }
    }

    final conversationId = state.selectedConversationId;
    if (conversationId == null) {
      return;
    }

    final updated = assistant.withSelectedVersion(index);
    if (updated.selectedVersionIndex == assistant.selectedVersionIndex &&
        updated.content == assistant.content) {
      return;
    }

    final messages = [...state.messages];
    messages[assistantIndex] = updated;
    state = state.copyWith(messages: messages, errorMessage: null);
    await _saveMessages(conversationId, [updated]);
    Log.d(
      'Chat assistant version selected: turnId=${updated.id}, '
      'index=${updated.selectedVersionIndex}',
      tag: 'Chat',
    );
  }

  @override
  ChatConversationMessage _assistantFromVersions({
    required String turnId,
    required DateTime createdAt,
    required List<ChatAssistantMessageVersion> versions,
    required int selectedVersionIndex,
  }) {
    final index = selectedVersionIndex.clamp(0, versions.length - 1);
    final version = versions[index];
    return ChatConversationMessage(
      id: turnId,
      role: ChatConversationRole.assistant,
      content: version.content,
      createdAt: createdAt,
      finishReason: version.finishReason,
      completionId: version.completionId,
      remoteResponseId: version.remoteResponseId,
      usage: version.usage,
      parts: version.parts,
      isInterrupted: version.isInterrupted,
      versions: versions,
      selectedVersionIndex: index,
    );
  }

  @override
  _LastAssistantTurn? _resolveLastAssistantTurn(
    List<ChatConversationMessage> messages,
  ) {
    var assistantIndex = -1;
    for (var index = messages.length - 1; index >= 0; index--) {
      final role = messages[index].role;
      if (role == ChatConversationRole.memory) {
        continue;
      }
      if (role == ChatConversationRole.assistant) {
        assistantIndex = index;
      }
      break;
    }
    if (assistantIndex < 0) {
      return null;
    }

    ChatConversationMessage? userMessage;
    var userIndex = -1;
    for (var index = assistantIndex - 1; index >= 0; index--) {
      if (messages[index].role == ChatConversationRole.user) {
        userMessage = messages[index];
        userIndex = index;
        break;
      }
    }
    if (userMessage == null || userIndex < 0) {
      return null;
    }

    return _LastAssistantTurn(
      assistantIndex: assistantIndex,
      assistant: messages[assistantIndex],
      userIndex: userIndex,
      userMessage: userMessage,
    );
  }

  @override
  Future<void> _restoreRegenerateTurnOnFailure({
    required String conversationId,
    required String errorMessage,
  }) async {
    final regenerate = _activeRegenerate;
    if (regenerate == null || regenerate.existingVersions.isEmpty) {
      state = state.copyWith(isSending: false, errorMessage: errorMessage);
      return;
    }

    final restored = _assistantFromVersions(
      turnId: regenerate.turnId,
      createdAt: regenerate.createdAt,
      versions: regenerate.existingVersions,
      selectedVersionIndex: regenerate.existingVersions.length - 1,
    );
    final messages = state.messages;
    final lastIsSameTurn =
        messages.isNotEmpty &&
        messages.last.role == ChatConversationRole.assistant &&
        messages.last.id == regenerate.turnId;
    state = state.copyWith(
      isSending: false,
      errorMessage: errorMessage,
      messages: lastIsSameTurn
          ? [...messages.sublist(0, messages.length - 1), restored]
          : [...messages, restored],
    );
    await _saveMessages(conversationId, [restored]);
  }
}
