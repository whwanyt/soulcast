import 'chat_assistant_message_version.dart';
import 'chat_conversation_role.dart';
import 'chat_message_part.dart';
import 'chat_usage_snapshot.dart';

/// 会话层使用的消息模型。
///
/// 助手消息的顶层字段始终表示当前选中版本，完整历史保存在 [versions]。
class ChatConversationMessage {
  const ChatConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.finishReason,
    this.completionId,
    this.remoteResponseId,
    this.usage,
    this.parts = const [],
    this.isInterrupted = false,
    this.versions = const [],
    this.selectedVersionIndex = 0,
  });

  factory ChatConversationMessage.user(
    String content, {
    List<ChatMessagePart> parts = const [],
  }) {
    return ChatConversationMessage(
      id: _createMessageId(),
      role: ChatConversationRole.user,
      content: content,
      createdAt: DateTime.now(),
      parts: parts,
    );
  }

  factory ChatConversationMessage.assistant({
    required String content,
    String? finishReason,
    String? completionId,
    String? remoteResponseId,
    ChatUsageSnapshot? usage,
    List<ChatMessagePart> parts = const [],
    bool isInterrupted = false,
  }) {
    final id = _createMessageId();
    final resolvedParts = parts.isNotEmpty
        ? parts
        : [
            if (content.trim().isNotEmpty)
              ChatTextPart(id: '$id-text', content: content),
          ];
    final message = ChatConversationMessage(
      id: id,
      role: ChatConversationRole.assistant,
      content: content,
      createdAt: DateTime.now(),
      finishReason: finishReason,
      completionId: completionId,
      remoteResponseId: remoteResponseId,
      usage: usage,
      parts: resolvedParts,
      isInterrupted: isInterrupted,
    );
    return message.withSyncedSingleVersion();
  }

  factory ChatConversationMessage.memory({required String content}) {
    return ChatConversationMessage(
      id: _createMessageId(),
      role: ChatConversationRole.memory,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  final String id;
  final ChatConversationRole role;
  final String content;
  final DateTime createdAt;
  final String? finishReason;
  final String? completionId;
  final String? remoteResponseId;
  final ChatUsageSnapshot? usage;
  final List<ChatMessagePart> parts;
  final bool isInterrupted;
  final List<ChatAssistantMessageVersion> versions;
  final int selectedVersionIndex;

  int get versionCount => versions.length;

  bool get hasMultipleVersions => versions.length > 1;

  /// 覆盖流式正文、parts 与版本选择的内容变化摘要。
  String get streamFingerprint {
    final partsFingerprint = parts.isEmpty
        ? ''
        : parts.map((part) => part.fingerprint).join('|');
    final versionsFingerprint = versions.isEmpty
        ? ''
        : versions.map((version) => version.fingerprint).join('||');
    return '$id|$content|$isInterrupted|$remoteResponseId|$selectedVersionIndex|'
        '$partsFingerprint|$versionsFingerprint';
  }

  /// 将当前顶层字段冻结为一个助手回复版本。
  ChatAssistantMessageVersion toVersionSnapshot({String? versionId}) {
    return ChatAssistantMessageVersion(
      id: versionId ?? (versions.isEmpty ? id : _createMessageId()),
      content: content,
      createdAt: createdAt,
      finishReason: finishReason,
      completionId: completionId,
      remoteResponseId: remoteResponseId,
      usage: usage,
      parts: parts,
      isInterrupted: isInterrupted,
    );
  }

  /// 确保助手消息至少有一个与顶层字段同步的版本。
  ChatConversationMessage withSyncedSingleVersion() {
    if (role != ChatConversationRole.assistant) {
      return this;
    }
    final version = ChatAssistantMessageVersion(
      id: versions.isNotEmpty ? versions.first.id : id,
      content: content,
      createdAt: createdAt,
      finishReason: finishReason,
      completionId: completionId,
      remoteResponseId: remoteResponseId,
      usage: usage,
      parts: parts,
      isInterrupted: isInterrupted,
    );
    return copyWith(versions: [version], selectedVersionIndex: 0);
  }

  /// 用当前顶层字段覆盖选中版本（继续回复 / 流式更新当前版）。
  ChatConversationMessage withUpdatedSelectedVersion() {
    if (role != ChatConversationRole.assistant) {
      return this;
    }
    if (versions.isEmpty) {
      return withSyncedSingleVersion();
    }
    final index = selectedVersionIndex.clamp(0, versions.length - 1);
    final selected = versions[index];
    final updated = selected.copyWith(
      content: content,
      finishReason: finishReason,
      completionId: completionId,
      remoteResponseId: remoteResponseId,
      usage: usage,
      parts: parts,
      isInterrupted: isInterrupted,
    );
    final nextVersions = [...versions];
    nextVersions[index] = updated;
    return copyWith(versions: nextVersions, selectedVersionIndex: index);
  }

  /// 追加新版本并选中（重新生成）。
  ChatConversationMessage withAppendedVersion(
    ChatAssistantMessageVersion version,
  ) {
    if (role != ChatConversationRole.assistant) {
      return this;
    }
    final baseVersions = versions.isEmpty
        ? [toVersionSnapshot(versionId: id)]
        : versions;
    final nextVersions = [...baseVersions, version];
    final index = nextVersions.length - 1;
    return copyWith(
      content: version.content,
      finishReason: version.finishReason,
      completionId: version.completionId,
      remoteResponseId: version.remoteResponseId,
      usage: version.usage,
      parts: version.parts,
      isInterrupted: version.isInterrupted,
      versions: nextVersions,
      selectedVersionIndex: index,
    );
  }

  /// 切换选中版本，并将顶层字段同步为该版本内容。
  ChatConversationMessage withSelectedVersion(int index) {
    if (role != ChatConversationRole.assistant || versions.isEmpty) {
      return this;
    }
    final clamped = index.clamp(0, versions.length - 1);
    final version = versions[clamped];
    return copyWith(
      content: version.content,
      finishReason: version.finishReason,
      completionId: version.completionId,
      remoteResponseId: version.remoteResponseId,
      usage: version.usage,
      parts: version.parts,
      isInterrupted: version.isInterrupted,
      selectedVersionIndex: clamped,
    );
  }

  ChatConversationMessage copyWith({
    String? id,
    ChatConversationRole? role,
    String? content,
    DateTime? createdAt,
    Object? finishReason = _unset,
    Object? completionId = _unset,
    Object? remoteResponseId = _unset,
    Object? usage = _unset,
    List<ChatMessagePart>? parts,
    bool? isInterrupted,
    List<ChatAssistantMessageVersion>? versions,
    int? selectedVersionIndex,
  }) {
    return ChatConversationMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      finishReason: finishReason == _unset
          ? this.finishReason
          : finishReason as String?,
      completionId: completionId == _unset
          ? this.completionId
          : completionId as String?,
      remoteResponseId: remoteResponseId == _unset
          ? this.remoteResponseId
          : remoteResponseId as String?,
      usage: usage == _unset ? this.usage : usage as ChatUsageSnapshot?,
      parts: parts ?? this.parts,
      isInterrupted: isInterrupted ?? this.isInterrupted,
      versions: versions ?? this.versions,
      selectedVersionIndex: selectedVersionIndex ?? this.selectedVersionIndex,
    );
  }
}

String _createMessageId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();
