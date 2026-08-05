import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/world_book/world_book.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/prompt/prompt.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

part 'widget/chat_info_helpers.dart';
part 'widget/chat_info_page_editor.dart';
part 'widget/chat_info_character_card.dart';
part 'widget/chat_info_basic_config_tab.dart';
part 'widget/chat_info_facts_tab.dart';
part 'widget/chat_info_fact_editor_sheet.dart';
part 'widget/chat_info_text_editor_sheet.dart';

/// 编辑指定会话的提示词、长期记忆与清理动作。
class ChatInfoPage extends ConsumerWidget {
  const ChatInfoPage({required this.conversationId, super.key});

  /// 路由指定的会话 id。
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(chatConversationsProvider);
    final conversation = conversations.whenOrNull(
      data: (items) => _findConversation(items, conversationId),
    );
    final characterId = conversation?.characterId;
    final characters = ref.watch(charactersProvider);
    final character = characterId == null
        ? null
        : characters.whenOrNull(
            data: (items) => _findCharacter(items, characterId),
          );
    final memory = ref.watch(chatConversationMemoryProvider(conversationId));
    final preferences = ref.watch(appPreferencesProvider);
    final appSystemPrompt = effectivePromptTemplate(
      id: PromptId.appSystem,
      customPrompts: preferences.customPrompts,
      t: context.t,
    );
    final worldBooks = ref.watch(worldBooksProvider).whenOrNull(data: (v) => v);
    final worldBookIds = conversation?.worldBookIds ?? const <String>[];
    final worldBooksSummary = _worldBooksSummary(
      context,
      worldBookIds,
      worldBooks,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.t.main.info.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: memory.when(
          data: (memory) => ChatInfoPageEditor(
            key: ValueKey(conversationId),
            conversationTitle: _conversationTitle(
              context,
              conversation?.title ?? defaultChatConversationTitle,
            ),
            conversationSystemPrompt: conversation?.systemPrompt,
            appSystemPrompt: appSystemPrompt,
            worldBooksSummary: worldBooksSummary,
            memory: memory,
            character: character,
            onEditCharacter: character == null
                ? null
                : () => CharacterEditRoute(
                    characterId: character.id,
                  ).push(context),
            isSaving: ref.watch(chatInfoEditorProvider).isLoading,
            onSave: (summary, facts) async {
              await ref
                  .read(chatInfoEditorProvider.notifier)
                  .saveMemory(
                    conversationId: conversationId,
                    summary: summary,
                    facts: facts,
                  );
            },
            onSystemPromptSave: (systemPrompt) async {
              await ref
                  .read(chatInfoEditorProvider.notifier)
                  .saveConversationSystemPrompt(
                    conversationId: conversationId,
                    systemPrompt: systemPrompt,
                  );
            },
            onWorldBooksEdited: () {
              _manageConversationWorldBooks(
                context,
                ref,
                conversationId,
                worldBookIds,
              );
            },
            onConversationClear: () async {
              await ref
                  .read(chatProvider.notifier)
                  .clearConversationMessages(conversationId);
            },
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
