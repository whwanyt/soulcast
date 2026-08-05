import 'package:isar_plus/isar_plus.dart';

import 'helper/chat_assistant_message_version_codec.dart';
import 'helper/chat_message_part_codec.dart';
import 'model/chat_conversation_message.dart';
import 'model/chat_conversation_role.dart';
import 'model/chat_usage_snapshot.dart';

part 'chat_message_entity.g.dart';

/// 会话消息及助手回复版本的本地持久化实体。
@collection
class ChatMessageEntity {
  ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.roleName,
    required this.content,
    required this.createdAt,
    this.finishReason,
    this.completionId,
    this.remoteResponseId,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.partsJson,
    this.isInterrupted = false,
    this.versionsJson,
    this.selectedVersionIndex = 0,
  });

  factory ChatMessageEntity.fromConversationMessage({
    required String conversationId,
    required ChatConversationMessage message,
  }) {
    return ChatMessageEntity(
      id: message.id,
      conversationId: conversationId,
      roleName: message.role.name,
      content: message.content,
      createdAt: message.createdAt,
      finishReason: message.finishReason,
      completionId: message.completionId,
      remoteResponseId: message.remoteResponseId,
      promptTokens: message.usage?.promptTokens,
      completionTokens: message.usage?.completionTokens,
      totalTokens: message.usage?.totalTokens,
      partsJson: encodeChatMessageParts(message.parts),
      isInterrupted: message.isInterrupted,
      versionsJson: encodeChatAssistantMessageVersions(message.versions),
      selectedVersionIndex: message.selectedVersionIndex,
    );
  }

  final String id;

  @Index(hash: true)
  final String conversationId;

  final String roleName;
  final String content;
  @Index()
  final DateTime createdAt;
  final String? finishReason;
  final String? completionId;
  final String? remoteResponseId;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final String? partsJson;
  final bool isInterrupted;
  final String? versionsJson;
  final int selectedVersionIndex;

  ChatConversationMessage toConversationMessage() {
    final versions = decodeChatAssistantMessageVersions(versionsJson);
    final message = ChatConversationMessage(
      id: id,
      role: ChatConversationRole.values.firstWhere(
        (role) => role.name == roleName,
        orElse: () => ChatConversationRole.assistant,
      ),
      content: content,
      createdAt: createdAt,
      finishReason: finishReason,
      completionId: completionId,
      remoteResponseId: remoteResponseId,
      usage: _usageSnapshot(),
      parts: decodeChatMessageParts(partsJson),
      isInterrupted: isInterrupted,
      versions: versions,
      selectedVersionIndex: selectedVersionIndex,
    );
    if (message.role == ChatConversationRole.assistant &&
        message.versions.isEmpty) {
      // 持久化消息应始终以版本列表作为助手多版本功能的统一数据源。
      return message.withSyncedSingleVersion();
    }
    return message;
  }

  ChatUsageSnapshot? _usageSnapshot() {
    final prompt = promptTokens;
    final completion = completionTokens;
    final total = totalTokens;
    if (prompt == null || completion == null || total == null) {
      return null;
    }
    return ChatUsageSnapshot(
      promptTokens: prompt,
      completionTokens: completion,
      totalTokens: total,
    );
  }
}
