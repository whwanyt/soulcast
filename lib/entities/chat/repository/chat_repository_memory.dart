part of 'chat_repository.dart';

extension ChatRepositoryMemory on ChatRepository {
  void saveMemory({
    required String conversationId,
    required String summary,
    required List<ChatMemoryFact> facts,
  }) {
    _isar.write((isar) {
      isar.collection<String, ChatConversationMemoryEntity>().put(
        ChatConversationMemoryEntity.fromMemory(
          ChatConversationMemory(
            conversationId: conversationId,
            summary: summary.trim(),
            facts: facts
                .map((fact) => fact.copyWith(content: fact.content.trim()))
                .where((fact) => fact.content.isNotEmpty)
                .toList(),
            updatedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  void clearMemory(String conversationId) {
    _isar.write((isar) {
      isar.collection<String, ChatConversationMemoryEntity>().delete(
        conversationId,
      );
    });
  }

  void saveDraftMessage({
    required String conversationId,
    required String draftMessage,
  }) {
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      if (existing == null || existing.draftMessage == draftMessage) {
        return;
      }

      conversations.put(
        existing.copyWith(
          draftMessage: draftMessage,
          updatedAt: DateTime.now(),
        ),
      );
    });
  }
}
