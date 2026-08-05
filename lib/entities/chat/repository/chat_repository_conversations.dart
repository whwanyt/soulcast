part of 'chat_repository.dart';

extension ChatRepositoryConversations on ChatRepository {
  List<ChatConversationEntity> getConversations() {
    return _sortConversations(
      _isar.collection<String, ChatConversationEntity>().where().findAll(),
    );
  }

  Stream<List<ChatConversationEntity>> watchConversations() {
    return _isar
        .collection<String, ChatConversationEntity>()
        .where()
        .watch(fireImmediately: true)
        .map(_sortConversations);
  }

  List<ChatConversationMessage> getMessages(String conversationId) {
    return _isar
        .collection<String, ChatMessageEntity>()
        .where()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAt()
        .findAll()
        .map((message) => message.toConversationMessage())
        .toList();
  }

  Stream<List<ChatConversationMessage>> watchMessages(String conversationId) {
    return _isar
        .collection<String, ChatMessageEntity>()
        .where()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAt()
        .watch(fireImmediately: true)
        .map(
          (messages) => messages
              .map((message) => message.toConversationMessage())
              .toList(),
        );
  }

  ChatConversationEntity? getConversation(String conversationId) {
    return _isar.collection<String, ChatConversationEntity>().get(
      conversationId,
    );
  }

  ChatConversationMemory getMemory(String conversationId) {
    final entity = _isar.collection<String, ChatConversationMemoryEntity>().get(
      conversationId,
    );
    return entity?.toMemory() ?? ChatConversationMemory.empty(conversationId);
  }

  Stream<ChatConversationMemory> watchMemory(String conversationId) {
    return _isar
        .collection<String, ChatConversationMemoryEntity>()
        .watchObject(conversationId, fireImmediately: true)
        .map(
          (entity) =>
              entity?.toMemory() ??
              ChatConversationMemory.empty(conversationId),
        );
  }

  ChatConversationEntity ensureConversation({
    String? conversationId,
    String? title,
    String? modelId,
    String? characterId,
  }) {
    final now = DateTime.now();
    final resolvedId = conversationId ?? _createConversationId();
    final existing = _isar.collection<String, ChatConversationEntity>().get(
      resolvedId,
    );
    if (existing != null) {
      return existing;
    }

    final conversation = ChatConversationEntity(
      id: resolvedId,
      title: resolveChatConversationTitle(title),
      createdAt: now,
      updatedAt: now,
      modelId: modelId,
      characterId: characterId,
      titleOrigin: characterId != null
          ? ChatConversationTitleOrigin.manual
          : ChatConversationTitleOrigin.pending,
    );
    _isar.write((isar) {
      isar.collection<String, ChatConversationEntity>().put(conversation);
    });
    return conversation;
  }

  List<ChatConversationEntity> getConversationsByCharacter(String characterId) {
    return _isar
        .collection<String, ChatConversationEntity>()
        .where()
        .characterIdEqualTo(characterId)
        .findAll();
  }

  void deleteConversationsByCharacter(String characterId) {
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final matched = conversations
          .where()
          .characterIdEqualTo(characterId)
          .findAll();
      if (matched.isEmpty) {
        return;
      }
      final messages = isar.collection<String, ChatMessageEntity>();
      final memories = isar.collection<String, ChatConversationMemoryEntity>();
      for (final conversation in matched) {
        messages.where().conversationIdEqualTo(conversation.id).deleteAll();
        memories.delete(conversation.id);
      }
      conversations.where().characterIdEqualTo(characterId).deleteAll();
    });
  }
}
