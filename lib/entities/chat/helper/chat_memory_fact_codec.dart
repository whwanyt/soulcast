import 'dart:convert';

import '../model/chat_memory_fact.dart';

/// 从持久化 JSON 解码非空记忆事实列表。
List<ChatMemoryFact> decodeChatMemoryFacts(String factsJson) {
  final trimmed = factsJson.trim();
  if (trimmed.isEmpty) {
    return const [];
  }

  final decoded = jsonDecode(trimmed);
  if (decoded is! List) {
    return const [];
  }

  return decoded
      .whereType<Map>()
      .map((item) => ChatMemoryFact.fromJson(item.cast<String, dynamic>()))
      .where((fact) => fact.content.trim().isNotEmpty)
      .toList();
}

/// 将结构化记忆事实编码为持久化 JSON。
String encodeChatMemoryFacts(List<ChatMemoryFact> facts) {
  return jsonEncode(facts.map((fact) => fact.toJson()).toList());
}
