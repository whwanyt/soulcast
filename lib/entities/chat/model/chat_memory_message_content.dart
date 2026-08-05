import 'dart:convert';

import 'package:flute_core/log/log.dart';

import 'chat_conversation_memory.dart';
import 'chat_memory_fact_category.dart';

/// 记忆消息 content 的结构化编解码（仅 UI 展示，不回放给模型）。
String encodeChatMemoryMessageContent(ChatConversationMemory memory) {
  return jsonEncode({
    'summary': memory.summary,
    'facts': [
      for (final fact in memory.facts)
        {'category': fact.category.name, 'content': fact.content},
    ],
  });
}

/// 解码仅供 UI 展示的记忆消息内容；无效结构返回 `null`。
({String summary, List<({String category, String content})> facts})?
decodeChatMemoryMessageContent(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      return null;
    }
    final summary = decoded['summary'] is String
        ? (decoded['summary'] as String).trim()
        : '';
    final factsSource = decoded['facts'];
    final facts = <({String category, String content})>[];
    if (factsSource is List) {
      for (final item in factsSource) {
        if (item is! Map) {
          continue;
        }
        final category = item['category'];
        final content = item['content'];
        if (content is! String || content.trim().isEmpty) {
          continue;
        }
        facts.add((
          category: category is String
              ? category
              : ChatMemoryFactCategory.other.name,
          content: content.trim(),
        ));
      }
    }
    return (summary: summary, facts: facts);
  } catch (error) {
    Log.w('Chat memory message content decode failed: $error', tag: 'Chat');
    return null;
  }
}
