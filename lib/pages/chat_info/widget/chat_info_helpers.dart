part of '../chat_info_page.dart';

/// 会话详情页编辑期间使用的可变事实草稿快照。
class _FactDraft {
  const _FactDraft({
    required this.id,
    required this.category,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _FactDraft.fromFact(ChatMemoryFact fact) {
    return _FactDraft(
      id: fact.id,
      category: fact.category,
      content: fact.content,
      createdAt: fact.createdAt,
      updatedAt: fact.updatedAt,
    );
  }

  final String id;
  final ChatMemoryFactCategory category;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  _FactDraft copyWith({
    ChatMemoryFactCategory? category,
    String? content,
    DateTime? updatedAt,
  }) {
    return _FactDraft(
      id: id,
      category: category ?? this.category,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  ChatMemoryFact toFact() {
    return ChatMemoryFact(
      id: id,
      category: category,
      content: content.trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

ChatConversationEntity? _findConversation(
  List<ChatConversationEntity> conversations,
  String conversationId,
) {
  for (final conversation in conversations) {
    if (conversation.id == conversationId) {
      return conversation;
    }
  }
  return null;
}

CharacterEntity? _findCharacter(
  List<CharacterEntity> characters,
  String characterId,
) {
  for (final character in characters) {
    if (character.id == characterId) {
      return character;
    }
  }
  return null;
}

String _conversationTitle(BuildContext context, String title) {
  return isDefaultChatConversationTitle(title)
      ? context.t.main.newConversation
      : title;
}

String? _normalizeOptionalText(String? value) {
  final normalizedValue = value?.trim();
  if (normalizedValue == null || normalizedValue.isEmpty) {
    return null;
  }
  return normalizedValue;
}

String _categoryLabel(BuildContext context, ChatMemoryFactCategory category) {
  final translations = context.t.main.info.category;
  return switch (category) {
    ChatMemoryFactCategory.relationship => translations.relationship,
    ChatMemoryFactCategory.worldSetting => translations.worldSetting,
    ChatMemoryFactCategory.plotState => translations.plotState,
    ChatMemoryFactCategory.preference => translations.preference,
    ChatMemoryFactCategory.constraint => translations.constraint,
    ChatMemoryFactCategory.other => translations.other,
  };
}

String _worldBooksSummary(
  BuildContext context,
  List<String> worldBookIds,
  List<WorldBookEntity>? books,
) {
  final translations = context.t.main.info;
  if (worldBookIds.isEmpty) {
    return translations.worldBooksEmpty;
  }
  final byId = {
    for (final book in books ?? const <WorldBookEntity>[]) book.id: book,
  };
  final names = worldBookIds
      .map((id) => byId[id]?.name ?? id)
      .toList(growable: false);
  return names.join('、');
}

Future<void> _manageConversationWorldBooks(
  BuildContext context,
  WidgetRef ref,
  String conversationId,
  List<String> currentIds,
) async {
  final translations = context.t.main.info;
  final books = (await ref.read(
    worldBookRepositoryProvider.future,
  )).getWorldBooks();
  if (!context.mounted) {
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      var ids = [...currentIds];
      return StatefulBuilder(
        builder: (context, setModalState) {
          final byId = {for (final book in books) book.id: book};
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      translations.worldBooksLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: translations.worldBooksAdd,
                      onPressed: () async {
                        final candidates = books
                            .where((book) => !ids.contains(book.id))
                            .toList();
                        if (candidates.isEmpty) {
                          SmartDialog.showToast(
                            translations.worldBooksNoAvailable,
                          );
                          return;
                        }
                        final selected = await showModalBottomSheet<String>(
                          context: context,
                          showDragHandle: true,
                          builder: (pickContext) {
                            return SafeArea(
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  for (final book in candidates)
                                    ListTile(
                                      title: Text(
                                        book.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => Navigator.of(
                                        pickContext,
                                      ).pop(book.id),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                        if (selected == null) {
                          return;
                        }
                        ids = [...ids, selected];
                        await ref
                            .read(chatInfoEditorProvider.notifier)
                            .saveConversationWorldBookIds(
                              conversationId: conversationId,
                              worldBookIds: ids,
                            );
                        setModalState(() {});
                      },
                      icon: const Icon(LucideIcons.plus),
                    ),
                  ),
                  if (ids.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        translations.worldBooksEmpty,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    for (final id in ids)
                      ListTile(
                        title: Text(
                          byId[id]?.name ?? id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: translations.worldBooksEdit,
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                WorldBookEditRoute(
                                  worldBookId: id,
                                ).push(context);
                              },
                              icon: const Icon(LucideIcons.penLine),
                            ),
                            IconButton(
                              tooltip: translations.worldBooksRemove,
                              onPressed: () async {
                                ids = ids.where((item) => item != id).toList();
                                await ref
                                    .read(chatInfoEditorProvider.notifier)
                                    .saveConversationWorldBookIds(
                                      conversationId: conversationId,
                                      worldBookIds: ids,
                                    );
                                setModalState(() {});
                              },
                              icon: const Icon(LucideIcons.x),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
