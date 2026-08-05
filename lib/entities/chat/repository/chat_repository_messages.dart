part of 'chat_repository.dart';

extension ChatRepositoryMessages on ChatRepository {
  ChatConversationEntity upsertConversationForMessages({
    required String conversationId,
    required List<ChatConversationMessage> messages,
  }) {
    final now = DateTime.now();
    late ChatConversationEntity conversation;
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      conversation =
          existing?.copyWith(
            title: _resolveTitleForSave(existing, messages),
            updatedAt: now,
          ) ??
          ChatConversationEntity(
            id: conversationId,
            title: resolveChatConversationTitle(_firstUserMessage(messages)),
            createdAt: now,
            updatedAt: now,
            modelId: existing?.modelId,
            titleOrigin: ChatConversationTitleOrigin.pending,
          );
      conversations.put(conversation);
    });
    return conversation;
  }

  void saveMessages({
    required String conversationId,
    required List<ChatConversationMessage> messages,
  }) {
    if (messages.isEmpty) {
      return;
    }

    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      final now = DateTime.now();
      final conversation =
          existing?.copyWith(
            title: _resolveTitleForSave(existing, messages),
            updatedAt: now,
          ) ??
          ChatConversationEntity(
            id: conversationId,
            title: resolveChatConversationTitle(_firstUserMessage(messages)),
            createdAt: now,
            updatedAt: now,
            modelId: existing?.modelId,
            titleOrigin: ChatConversationTitleOrigin.pending,
          );

      conversations.put(conversation);
      isar.collection<String, ChatMessageEntity>().putAll(
        messages
            .map(
              (message) => ChatMessageEntity.fromConversationMessage(
                conversationId: conversationId,
                message: message,
              ),
            )
            .toList(),
      );
    });
  }

  void clearMessages(String conversationId) {
    _isar.write((isar) {
      final messages = isar.collection<String, ChatMessageEntity>();
      messages.where().conversationIdEqualTo(conversationId).deleteAll();

      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      if (existing != null) {
        conversations.put(
          existing.copyWith(
            title: defaultChatConversationTitle,
            titleOrigin: ChatConversationTitleOrigin.pending,
            updatedAt: DateTime.now(),
          ),
        );
      }
    });
  }

  void deleteMessages({
    required String conversationId,
    required List<String> ids,
  }) {
    if (ids.isEmpty) {
      return;
    }

    _isar.write((isar) {
      final messages = isar.collection<String, ChatMessageEntity>();
      for (final id in ids) {
        final existing = messages.get(id);
        if (existing == null || existing.conversationId != conversationId) {
          continue;
        }
        messages.delete(id);
      }

      final conversations = isar.collection<String, ChatConversationEntity>();
      final conversation = conversations.get(conversationId);
      if (conversation != null) {
        conversations.put(conversation.copyWith(updatedAt: DateTime.now()));
      }
    });
  }
}
