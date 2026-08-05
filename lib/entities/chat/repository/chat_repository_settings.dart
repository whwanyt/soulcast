part of 'chat_repository.dart';

extension ChatRepositorySettings on ChatRepository {
  void setConversationPinned({
    required String conversationId,
    required bool isPinned,
  }) {
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      if (existing == null || existing.isPinned == isPinned) {
        return;
      }

      conversations.put(existing.copyWith(isPinned: isPinned));
    });
  }

  bool renameConversation({
    required String conversationId,
    required String title,
  }) {
    var renamed = false;
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      if (existing == null) {
        return;
      }

      final trimmed = title.trim();
      if (trimmed.isEmpty) {
        if (existing.title == defaultChatConversationTitle &&
            existing.titleOrigin == ChatConversationTitleOrigin.pending) {
          return;
        }
        conversations.put(
          existing.copyWith(
            title: defaultChatConversationTitle,
            titleOrigin: ChatConversationTitleOrigin.pending,
            updatedAt: DateTime.now(),
          ),
        );
        renamed = true;
        return;
      }

      final resolvedTitle = resolveChatConversationTitle(trimmed);
      if (existing.title == resolvedTitle &&
          existing.titleOrigin == ChatConversationTitleOrigin.manual) {
        return;
      }

      conversations.put(
        existing.copyWith(
          title: resolvedTitle,
          titleOrigin: ChatConversationTitleOrigin.manual,
          updatedAt: DateTime.now(),
        ),
      );
      renamed = true;
    });
    return renamed;
  }

  /// 应用 LLM 自动标题；仅当当前仍为 `pending` 时成功。
  bool applyGeneratedTitle({
    required String conversationId,
    required String title,
  }) {
    var applied = false;
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      if (existing == null ||
          !canAutoGenerateChatConversationTitle(existing.titleOrigin) ||
          existing.characterId != null) {
        return;
      }

      final resolvedTitle = sanitizeGeneratedChatConversationTitle(title);
      if (resolvedTitle == null) {
        return;
      }

      conversations.put(
        existing.copyWith(
          title: resolvedTitle,
          titleOrigin: ChatConversationTitleOrigin.generated,
          updatedAt: DateTime.now(),
        ),
      );
      applied = true;
    });
    return applied;
  }

  void saveConversationModel({
    required String conversationId,
    required String? modelId,
  }) {
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      if (existing == null || existing.modelId == modelId) {
        return;
      }

      conversations.put(
        existing.copyWith(modelId: modelId, updatedAt: DateTime.now()),
      );
    });
  }

  void saveConversationSystemPrompt({
    required String conversationId,
    required String? systemPrompt,
  }) {
    final normalizedPrompt = _normalizeSystemPrompt(systemPrompt);
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      if (existing == null || existing.systemPrompt == normalizedPrompt) {
        return;
      }

      conversations.put(
        existing.copyWith(
          systemPrompt: normalizedPrompt,
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  void setConversationWorldBookIds({
    required String conversationId,
    required List<String> worldBookIds,
  }) {
    final normalized = worldBookIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      final existing = conversations.get(conversationId);
      if (existing == null) {
        return;
      }
      conversations.put(
        existing.copyWith(worldBookIds: normalized, updatedAt: DateTime.now()),
      );
    });
  }

  /// 删除世界书后清理所有会话上的引用。
  void clearWorldBookReferences(String worldBookId) {
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      for (final conversation in conversations.where().findAll()) {
        if (!conversation.worldBookIds.contains(worldBookId)) {
          continue;
        }
        conversations.put(
          conversation.copyWith(
            worldBookIds: conversation.worldBookIds
                .where((id) => id != worldBookId)
                .toList(growable: false),
            updatedAt: DateTime.now(),
          ),
        );
      }
    });
  }

  bool deleteConversation(String conversationId) {
    var deleted = false;
    _isar.write((isar) {
      final conversations = isar.collection<String, ChatConversationEntity>();
      deleted = conversations.delete(conversationId);
      if (!deleted) {
        return;
      }

      isar
          .collection<String, ChatMessageEntity>()
          .where()
          .conversationIdEqualTo(conversationId)
          .deleteAll();
      isar.collection<String, ChatConversationMemoryEntity>().delete(
        conversationId,
      );
    });
    return deleted;
  }
}
