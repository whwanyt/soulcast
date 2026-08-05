part of 'chat.dart';

/// Chat notifier 的长期记忆读取、编辑与触发更新能力。
mixin _ChatMemoryActions on _ChatController {
  @override
  Future<ChatConversationMemory> _loadMemory(String conversationId) async {
    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      return repository.getMemory(conversationId);
    } catch (error, stackTrace) {
      Log.e(
        'Chat memory load failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      return ChatConversationMemory.empty(conversationId);
    }
  }

  @override
  Future<void> _updateMemoryAfterCompletion({
    required LlmClient client,
    required ChatSettings settings,
    required String conversationId,
    required ChatConversationMemory memory,
    required ChatConversationMessage userMessage,
    required ChatCompletionResult completionResult,
  }) async {
    final memoryWriteFrequency = ref
        .read(appPreferencesProvider)
        .effectiveMemoryWriteFrequency;
    if (memoryWriteFrequency == null) {
      Log.d('Chat memory update skipped: disabled by settings', tag: 'Chat');
      return;
    }

    if (completionResult.isToolCallsExceeded) {
      Log.d('Chat memory update skipped: tool calls exceeded', tag: 'Chat');
      return;
    }

    final assistantMessage = completionResult.lastAssistantMessage;
    if (assistantMessage == null) {
      Log.d(
        'Chat memory update skipped: missing assistant message',
        tag: 'Chat',
      );
      return;
    }

    final userTurnsSinceLastMemory = _userTurnsSinceLastMemory(state.messages);
    if (userTurnsSinceLastMemory < memoryWriteFrequency) {
      Log.d(
        'Chat memory update skipped: frequency=$memoryWriteFrequency, '
        'turnsSinceLastMemory=$userTurnsSinceLastMemory',
        tag: 'Chat',
      );
      return;
    }

    final preferences = ref.read(appPreferencesProvider);
    final userPromptId = settings.isRolePlay
        ? PromptId.memoryUpdateUserRolePlay
        : PromptId.memoryUpdateUserNormal;
    final updatedMemory = await ref
        .read(chatMemoryUpdateServiceProvider)
        .updateMemory(
          client: client,
          settings: settings,
          memory: memory,
          userMessage: userMessage,
          assistantMessage: assistantMessage,
          systemTemplate: effectivePromptTemplate(
            id: PromptId.memoryUpdateSystem,
            customPrompts: preferences.customPrompts,
            t: t,
          ),
          userTemplate: effectivePromptTemplate(
            id: userPromptId,
            customPrompts: preferences.customPrompts,
            t: t,
          ),
          systemFallbackTemplate: defaultPromptTemplate(
            t,
            PromptId.memoryUpdateSystem,
          ),
          userFallbackTemplate: defaultPromptTemplate(t, userPromptId),
        );
    if (updatedMemory == null) {
      return;
    }

    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.saveMemory(
        conversationId: conversationId,
        summary: updatedMemory.summary,
        facts: updatedMemory.facts,
      );
      final memoryMessage = ChatConversationMessage.memory(
        content: encodeChatMemoryMessageContent(updatedMemory),
      );
      await _saveMessages(conversationId, [memoryMessage]);
      if (state.selectedConversationId == conversationId) {
        state = state.copyWith(messages: [...state.messages, memoryMessage]);
      }
      Log.d(
        'Chat memory updated: conversationId=$conversationId, '
        'facts=${updatedMemory.facts.length}',
        tag: 'Chat',
      );
    } catch (error, stackTrace) {
      Log.e(
        'Chat memory persist failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  int _userTurnsSinceLastMemory(List<ChatConversationMessage> messages) {
    var count = 0;
    for (var index = messages.length - 1; index >= 0; index--) {
      final message = messages[index];
      if (message.role == ChatConversationRole.memory) {
        break;
      }
      if (message.role == ChatConversationRole.user) {
        count++;
      }
    }
    return count;
  }
}
