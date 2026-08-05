import 'chat_memory_fact.dart';

/// 单个会话的长期记忆，由摘要与结构化事实组成。
class ChatConversationMemory {
  const ChatConversationMemory({
    required this.conversationId,
    required this.summary,
    required this.facts,
    required this.updatedAt,
  });

  factory ChatConversationMemory.empty(String conversationId) {
    return ChatConversationMemory(
      conversationId: conversationId,
      summary: '',
      facts: const [],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String conversationId;
  final String summary;
  final List<ChatMemoryFact> facts;
  final DateTime updatedAt;

  bool get isEmpty => summary.trim().isEmpty && facts.isEmpty;
  bool get isNotEmpty => !isEmpty;

  ChatConversationMemory copyWith({
    String? conversationId,
    String? summary,
    List<ChatMemoryFact>? facts,
    DateTime? updatedAt,
  }) {
    return ChatConversationMemory(
      conversationId: conversationId ?? this.conversationId,
      summary: summary ?? this.summary,
      facts: facts ?? this.facts,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
