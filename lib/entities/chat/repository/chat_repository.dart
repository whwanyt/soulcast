import 'package:isar_plus/isar_plus.dart';

import '../chat_conversation_entity.dart';
import '../chat_conversation_memory_entity.dart';
import '../chat_message_entity.dart';
import '../helper/chat_conversation_title.dart';
import '../model/chat_conversation_memory.dart';
import '../model/chat_conversation_message.dart';
import '../model/chat_conversation_role.dart';
import '../model/chat_conversation_title_origin.dart';
import '../model/chat_memory_fact.dart';

part 'chat_repository_conversations.dart';
part 'chat_repository_messages.dart';
part 'chat_repository_settings.dart';
part 'chat_repository_maintenance.dart';
part 'chat_repository_memory.dart';

/// 会话、消息、长期记忆与输入草稿的 Isar 仓库。
///
/// 涉及会话及其关联数据的写入在事务内完成，避免留下孤立消息或记忆。
class ChatRepository {
  const ChatRepository(this._isar);

  final Isar _isar;

  String createConversationId() => _createConversationId();

  String _resolveTitleForSave(
    ChatConversationEntity existing,
    List<ChatConversationMessage> messages,
  ) {
    if (canAutoGenerateChatConversationTitle(existing.titleOrigin) &&
        isDefaultChatConversationTitle(existing.title)) {
      return resolveChatConversationTitle(_firstUserMessage(messages));
    }
    return existing.title;
  }

  String? _firstUserMessage(List<ChatConversationMessage> messages) {
    for (final message in messages) {
      if (message.role == ChatConversationRole.user) {
        return message.content;
      }
    }
    return null;
  }

  String? _normalizeSystemPrompt(String? systemPrompt) {
    final normalizedPrompt = systemPrompt?.trim();
    if (normalizedPrompt == null || normalizedPrompt.isEmpty) {
      return null;
    }
    return normalizedPrompt;
  }
}

List<ChatConversationEntity> _sortConversations(
  List<ChatConversationEntity> conversations,
) {
  return [...conversations]..sort((first, second) {
    if (first.isPinned != second.isPinned) {
      return first.isPinned ? -1 : 1;
    }
    return second.updatedAt.compareTo(first.updatedAt);
  });
}

String _createConversationId() {
  return 'chat_${DateTime.now().microsecondsSinceEpoch}';
}
