import 'package:isar_plus/isar_plus.dart';

import 'model/chat_conversation_title_origin.dart';

part 'chat_conversation_entity.g.dart';

/// 会话摘要、模型选择与页面草稿的本地持久化实体。
@collection
class ChatConversationEntity {
  ChatConversationEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.draftMessage = '',
    this.isPinned = false,
    this.modelId,
    this.systemPrompt,
    this.characterId,
    this.worldBookIds = const [],
    this.titleOrigin = ChatConversationTitleOrigin.pending,
  });

  final String id;

  String title;
  String draftMessage;
  bool isPinned;
  String? modelId;
  String? systemPrompt;

  /// 关联的角色 id；`null` 表示普通会话，创建后不可更改。
  @Index()
  String? characterId;

  /// 本会话额外绑定的世界书 id 列表。
  List<String> worldBookIds;

  /// 标题来源：决定是否允许自动生成/覆盖。
  ChatConversationTitleOrigin titleOrigin;

  @Index()
  DateTime createdAt;

  @Index()
  DateTime updatedAt;

  ChatConversationEntity copyWith({
    String? title,
    String? draftMessage,
    bool? isPinned,
    Object? modelId = _unset,
    Object? systemPrompt = _unset,
    List<String>? worldBookIds,
    ChatConversationTitleOrigin? titleOrigin,
    DateTime? updatedAt,
  }) {
    return ChatConversationEntity(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      draftMessage: draftMessage ?? this.draftMessage,
      isPinned: isPinned ?? this.isPinned,
      modelId: modelId == _unset ? this.modelId : modelId as String?,
      systemPrompt: systemPrompt == _unset
          ? this.systemPrompt
          : systemPrompt as String?,
      characterId: characterId,
      worldBookIds: worldBookIds ?? this.worldBookIds,
      titleOrigin: titleOrigin ?? this.titleOrigin,
    );
  }
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();
