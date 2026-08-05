import 'dart:convert';

import '../model/chat_message_part.dart';

/// 将消息片段编码为持久化 JSON；空列表返回 `null`。
String? encodeChatMessageParts(List<ChatMessagePart> parts) {
  if (parts.isEmpty) {
    return null;
  }
  return jsonEncode([for (final part in parts) part.toJson()]);
}

/// 从持久化 JSON 解码结构化消息片段。
List<ChatMessagePart> decodeChatMessageParts(String? partsJson) {
  if (partsJson == null || partsJson.trim().isEmpty) {
    return const [];
  }

  final decoded = jsonDecode(partsJson);
  if (decoded is! List) {
    return const [];
  }

  return [
    for (final item in decoded)
      if (item is Map<String, dynamic>)
        ChatMessagePart.fromJson(item)
      else if (item is Map)
        ChatMessagePart.fromJson(Map<String, dynamic>.from(item)),
  ];
}
