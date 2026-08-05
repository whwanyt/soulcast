part of 'chat.dart';

/// Chat notifier 的会话标题自动生成与持久化能力。
mixin _ChatTitleActions on _ChatController {
  @override
  Future<void> _updateTitleAfterCompletion({
    required LlmClient client,
    required ChatSettings settings,
    required String conversationId,
    required ChatConversationMessage userMessage,
    required ChatCompletionResult completionResult,
  }) async {
    try {
      final repository = await ref.read(chatRepositoryProvider.future);
      final conversation = repository.getConversation(conversationId);
      if (conversation == null) {
        Log.d('Chat title update skipped: conversation missing', tag: 'Chat');
        return;
      }
      if (conversation.characterId != null) {
        Log.d('Chat title update skipped: character conversation', tag: 'Chat');
        return;
      }
      if (!canAutoGenerateChatConversationTitle(conversation.titleOrigin)) {
        Log.d(
          'Chat title update skipped: titleOrigin=${conversation.titleOrigin.name}',
          tag: 'Chat',
        );
        return;
      }

      final assistantMessage = completionResult.lastAssistantMessage;
      if (assistantMessage == null) {
        Log.d(
          'Chat title update skipped: missing assistant message',
          tag: 'Chat',
        );
        return;
      }

      final titleUserMessage = _firstUserMessage(state.messages) ?? userMessage;
      if (titleUserMessage.content.trim().isEmpty &&
          assistantMessage.content.trim().isEmpty) {
        Log.d('Chat title update skipped: empty content', tag: 'Chat');
        return;
      }

      final preferences = ref.read(appPreferencesProvider);
      final generatedTitle = await ref
          .read(chatTitleUpdateServiceProvider)
          .generateTitle(
            client: client,
            settings: settings,
            userMessage: titleUserMessage,
            assistantMessage: assistantMessage,
            systemTemplate: effectivePromptTemplate(
              id: PromptId.titleSystem,
              customPrompts: preferences.customPrompts,
              t: t,
            ),
            userTemplate: effectivePromptTemplate(
              id: PromptId.titleUser,
              customPrompts: preferences.customPrompts,
              t: t,
            ),
            systemFallbackTemplate: defaultPromptTemplate(
              t,
              PromptId.titleSystem,
            ),
            userFallbackTemplate: defaultPromptTemplate(t, PromptId.titleUser),
          );
      if (generatedTitle == null) {
        return;
      }

      final applied = repository.applyGeneratedTitle(
        conversationId: conversationId,
        title: generatedTitle,
      );
      Log.d(
        'Chat title update ${applied ? 'applied' : 'skipped'}: '
        'conversationId=$conversationId, title=$generatedTitle',
        tag: 'Chat',
      );
    } catch (error, stackTrace) {
      Log.e(
        'Chat title update failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  ChatConversationMessage? _firstUserMessage(
    List<ChatConversationMessage> messages,
  ) {
    for (final message in messages) {
      if (message.role == ChatConversationRole.user) {
        return message;
      }
    }
    return null;
  }
}
