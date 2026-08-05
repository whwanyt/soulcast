part of 'chat.dart';

/// Chat notifier 的普通会话与角色会话创建。
mixin _ChatConversationCreationActions on _ChatConversationActions {
  Future<void> startNewConversation() async {
    final repository = await ref.read(chatRepositoryProvider.future);
    final conversation = repository.ensureConversation(
      conversationId: repository.createConversationId(),
    );
    await selectConversation(conversation.id);
  }

  /// 从角色列表创建一个新的角色会话，并选中它。
  ///
  /// 每次调用都会创建独立会话，不复用该角色的历史会话。
  /// [greeting] 为选定开场白；为空时不写入首条助手消息。
  Future<void> startConversationForCharacter(
    String characterId, {
    String? greeting,
  }) async {
    final characterRepository = await ref.read(
      characterRepositoryProvider.future,
    );
    final character = characterRepository.getCharacter(characterId);
    if (character == null) {
      Log.d(
        'Chat start for character skipped: character not found: $characterId',
        tag: 'Chat',
      );
      state = state.copyWith(errorMessage: t.characterManagement.notFound);
      return;
    }

    final repository = await ref.read(chatRepositoryProvider.future);
    final conversation = repository.ensureConversation(
      conversationId: repository.createConversationId(),
      title: character.name,
      characterId: character.id,
    );
    characterRepository.markCharacterUsed(character.id);
    final resolvedGreeting = (greeting ?? character.primaryGreeting).trim();
    if (resolvedGreeting.isNotEmpty) {
      await _saveMessages(conversation.id, [
        ChatConversationMessage.assistant(
          content: resolvedGreeting,
          finishReason: 'stop',
        ),
      ]);
    }
    Log.d(
      'Chat conversation created for character: '
      'conversationId=${conversation.id}, characterId=${character.id}',
      tag: 'Chat',
    );
    await selectConversation(conversation.id);
  }
}
