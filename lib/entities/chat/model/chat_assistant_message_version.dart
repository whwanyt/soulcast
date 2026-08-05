import 'chat_message_part.dart';
import 'chat_usage_snapshot.dart';

/// 一条助手消息的独立回复版本快照。
class ChatAssistantMessageVersion {
  const ChatAssistantMessageVersion({
    required this.id,
    required this.content,
    required this.createdAt,
    this.finishReason,
    this.completionId,
    this.remoteResponseId,
    this.usage,
    this.parts = const [],
    this.isInterrupted = false,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final String? finishReason;
  final String? completionId;
  final String? remoteResponseId;
  final ChatUsageSnapshot? usage;
  final List<ChatMessagePart> parts;
  final bool isInterrupted;

  /// 用于列表缓存判断内容是否变化的稳定摘要。
  String get fingerprint {
    final partsFingerprint = parts.isEmpty
        ? ''
        : parts.map((part) => part.fingerprint).join('|');
    return '$id|$content|$isInterrupted|$remoteResponseId|$partsFingerprint';
  }

  ChatAssistantMessageVersion copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    Object? finishReason = _unset,
    Object? completionId = _unset,
    Object? remoteResponseId = _unset,
    Object? usage = _unset,
    List<ChatMessagePart>? parts,
    bool? isInterrupted,
  }) {
    return ChatAssistantMessageVersion(
      id: id ?? this.id,
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
    );
  }
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();
