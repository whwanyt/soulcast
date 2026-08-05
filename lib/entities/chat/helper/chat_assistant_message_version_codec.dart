import 'dart:convert';

import '../model/chat_assistant_message_version.dart';
import '../model/chat_message_part.dart';
import '../model/chat_usage_snapshot.dart';
import 'chat_message_part_codec.dart';

/// 将助手回复版本列表编码为持久化 JSON；空列表返回 `null`。
String? encodeChatAssistantMessageVersions(
  List<ChatAssistantMessageVersion> versions,
) {
  if (versions.isEmpty) {
    return null;
  }
  return jsonEncode([for (final version in versions) _versionToJson(version)]);
}

/// 从持久化 JSON 解码助手回复版本列表。
List<ChatAssistantMessageVersion> decodeChatAssistantMessageVersions(
  String? versionsJson,
) {
  if (versionsJson == null || versionsJson.trim().isEmpty) {
    return const [];
  }

  final decoded = jsonDecode(versionsJson);
  if (decoded is! List) {
    return const [];
  }

  return [
    for (final item in decoded)
      if (item is Map<String, dynamic>)
        _versionFromJson(item)
      else if (item is Map)
        _versionFromJson(Map<String, dynamic>.from(item)),
  ];
}

Map<String, dynamic> _versionToJson(ChatAssistantMessageVersion version) {
  return {
    'id': version.id,
    'content': version.content,
    'createdAt': version.createdAt.toIso8601String(),
    'finishReason': version.finishReason,
    'completionId': version.completionId,
    'remoteResponseId': version.remoteResponseId,
    'promptTokens': version.usage?.promptTokens,
    'completionTokens': version.usage?.completionTokens,
    'totalTokens': version.usage?.totalTokens,
    'parts': [for (final part in version.parts) part.toJson()],
    'isInterrupted': version.isInterrupted,
  };
}

ChatAssistantMessageVersion _versionFromJson(Map<String, dynamic> json) {
  final partsRaw = json['parts'];
  final parts = <ChatMessagePart>[];
  if (partsRaw is List) {
    for (final item in partsRaw) {
      if (item is Map<String, dynamic>) {
        parts.add(ChatMessagePart.fromJson(item));
      } else if (item is Map) {
        parts.add(ChatMessagePart.fromJson(Map<String, dynamic>.from(item)));
      }
    }
  } else if (partsRaw is String) {
    parts.addAll(decodeChatMessageParts(partsRaw));
  }

  final createdAtRaw = json['createdAt'] as String?;
  return ChatAssistantMessageVersion(
    id: json['id'] as String,
    content: json['content'] as String? ?? '',
    createdAt: createdAtRaw == null
        ? DateTime.now()
        : DateTime.parse(createdAtRaw),
    finishReason: json['finishReason'] as String?,
    completionId: json['completionId'] as String?,
    remoteResponseId: json['remoteResponseId'] as String?,
    usage: _usageFromJson(json),
    parts: parts,
    isInterrupted: json['isInterrupted'] as bool? ?? false,
  );
}

ChatUsageSnapshot? _usageFromJson(Map<String, dynamic> json) {
  final prompt = json['promptTokens'] as int?;
  final completion = json['completionTokens'] as int?;
  final total = json['totalTokens'] as int?;
  if (prompt == null || completion == null || total == null) {
    return null;
  }
  return ChatUsageSnapshot(
    promptTokens: prompt,
    completionTokens: completion,
    totalTokens: total,
  );
}
