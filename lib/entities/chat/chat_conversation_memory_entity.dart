import 'package:flute_core/log/log.dart';
import 'package:isar_plus/isar_plus.dart';

import 'helper/chat_memory_fact_codec.dart';
import 'model/chat_conversation_memory.dart';
import 'model/chat_memory_fact.dart';

part 'chat_conversation_memory_entity.g.dart';

/// 会话长期记忆的本地持久化实体。
@collection
class ChatConversationMemoryEntity {
  ChatConversationMemoryEntity({
    required this.conversationId,
    required this.summary,
    required this.factsJson,
    required this.updatedAt,
  });

  factory ChatConversationMemoryEntity.fromMemory(
    ChatConversationMemory memory,
  ) {
    return ChatConversationMemoryEntity(
      conversationId: memory.conversationId,
      summary: memory.summary,
      factsJson: encodeChatMemoryFacts(memory.facts),
      updatedAt: memory.updatedAt,
    );
  }

  @id
  final String conversationId;
  String summary;
  String factsJson;

  @Index()
  DateTime updatedAt;

  ChatConversationMemory toMemory() {
    return ChatConversationMemory(
      conversationId: conversationId,
      summary: summary,
      facts: decodeFacts(),
      updatedAt: updatedAt,
    );
  }

  List<ChatMemoryFact> decodeFacts() {
    try {
      return decodeChatMemoryFacts(factsJson);
    } catch (error) {
      // 单条损坏记忆不应阻断会话加载，退化为空事实列表并保留诊断信息。
      Log.w(
        'Chat memory facts decode failed: conversationId=$conversationId, '
        'error=$error',
        tag: 'Chat',
      );
      return const [];
    }
  }
}
