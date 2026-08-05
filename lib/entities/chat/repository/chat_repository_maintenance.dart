part of 'chat_repository.dart';

extension ChatRepositoryMaintenance on ChatRepository {
  int countMessages() {
    return _isar.collection<String, ChatMessageEntity>().count();
  }

  int countConversations() {
    return _isar.collection<String, ChatConversationEntity>().count();
  }

  void deleteAllConversations() {
    _isar.write((isar) {
      isar.collection<String, ChatConversationEntity>().clear();
      isar.collection<String, ChatMessageEntity>().clear();
      isar.collection<String, ChatConversationMemoryEntity>().clear();
    });
  }
}
