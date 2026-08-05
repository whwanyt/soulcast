import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/chat_info/chat_info_page.dart';

void main() {
  testWidgets('Chat info editor saves summary and edits facts in sheet', (
    tester,
  ) async {
    final saves = <(String, List<ChatMemoryFact>)>[];
    final systemPromptSaves = <String?>[];
    var didClearConversation = false;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: ChatInfoPageEditor(
              conversationTitle: '记忆测试',
              conversationSystemPrompt: null,
              appSystemPrompt: '应用级提示词',
              worldBooksSummary: '未绑定世界书',
              memory: ChatConversationMemory(
                conversationId: 'chat_memory',
                summary: '旧摘要',
                facts: [
                  ChatMemoryFact(
                    id: 'fact_role',
                    category: ChatMemoryFactCategory.relationship,
                    content: '旧事实',
                    createdAt: DateTime(2026),
                    updatedAt: DateTime(2026),
                  ),
                ],
                updatedAt: DateTime(2026),
              ),
              isSaving: false,
              onSave: (summary, facts) async {
                saves.add((summary, facts));
              },
              onWorldBooksEdited: () {},
              onSystemPromptSave: (systemPrompt) async {
                systemPromptSaves.add(systemPrompt);
              },
              onConversationClear: () async {
                didClearConversation = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text(t.main.info.basicConfigTab), findsWidgets);
    expect(find.text(t.main.info.memoriesTab), findsOneWidget);
    expect(find.text('旧摘要'), findsOneWidget);
    expect(find.text(t.main.info.usingAppSystemPrompt), findsOneWidget);
    expect(find.text('应用级提示词'), findsOneWidget);
    expect(find.widgetWithText(TextField, '旧摘要'), findsNothing);
    expect(find.text(t.main.info.clearConversation), findsOneWidget);

    await tester.tap(find.text(t.main.info.clearConversation));
    await tester.pumpAndSettle();
    expect(find.text(t.main.info.clearConversationTitle), findsOneWidget);
    await tester.tap(find.text(t.main.info.clearConversationConfirm).last);
    await tester.pumpAndSettle();
    expect(didClearConversation, isTrue);

    await tester.tap(find.text('旧摘要'));
    await tester.pumpAndSettle();
    expect(find.text(t.main.info.editSummary), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, t.main.info.summaryLabel),
      '新摘要',
    );
    await tester.tap(find.byKey(const ValueKey('chat_info_text_save_button')));
    await tester.pumpAndSettle();

    expect(saves.last.$1, '新摘要');
    expect(saves.last.$2, hasLength(1));
    expect(find.text('新摘要'), findsOneWidget);

    await tester.tap(find.text('应用级提示词'));
    await tester.pumpAndSettle();
    expect(find.text(t.main.info.editSystemPrompt), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, t.main.info.systemPromptLabel),
      '会话级提示词',
    );
    await tester.tap(find.byKey(const ValueKey('chat_info_text_save_button')));
    await tester.pumpAndSettle();

    expect(systemPromptSaves.last, '会话级提示词');
    expect(find.text('会话级提示词'), findsOneWidget);

    await tester.tap(find.text(t.main.info.memoriesTab));
    await tester.pumpAndSettle();

    expect(find.text('旧事实'), findsOneWidget);
    expect(find.widgetWithText(TextField, '旧事实'), findsNothing);

    await tester.tap(find.text('旧事实'));
    await tester.pumpAndSettle();

    expect(find.text(t.main.info.editMemory), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, t.main.info.memoryContentLabel),
      '新事实',
    );
    await tester.tap(find.byKey(const ValueKey('chat_info_fact_save_button')));
    await tester.pumpAndSettle();

    expect(saves.last.$2, hasLength(1));
    expect(saves.last.$2.single.content, '新事实');
    expect(find.text('新事实'), findsOneWidget);

    await tester.tap(find.byTooltip(t.main.info.addMemory));
    await tester.pumpAndSettle();
    expect(find.text(t.main.info.addMemory), findsWidgets);
    await tester.enterText(
      find.widgetWithText(TextField, t.main.info.memoryContentLabel),
      '新增事实',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('chat_info_fact_save_button')));
    await tester.pumpAndSettle();

    expect(saves.last.$2, hasLength(2));
    expect(saves.last.$2.map((fact) => fact.content), contains('新事实'));
    expect(saves.last.$2.map((fact) => fact.content), contains('新增事实'));

    await tester.tap(find.byTooltip(t.main.info.deleteMemory).first);
    await tester.pump();

    expect(saves.last.$2, hasLength(1));
    expect(saves.last.$2.single.content, '新增事实');
  });

  testWidgets('Chat info page keeps facts tab after memory refresh', (
    tester,
  ) async {
    final memoryController = StreamController<ChatConversationMemory>();
    addTearDown(memoryController.close);

    final now = DateTime(2026);
    final conversation = ChatConversationEntity(
      id: 'chat_info_refresh',
      title: '记忆刷新测试',
      createdAt: now,
      updatedAt: now,
    );
    final oldFact = ChatMemoryFact(
      id: 'fact_old',
      category: ChatMemoryFactCategory.relationship,
      content: '旧事实',
      createdAt: now,
      updatedAt: now,
    );
    final newFact = ChatMemoryFact(
      id: 'fact_new',
      category: ChatMemoryFactCategory.plotState,
      content: '新增事实',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            chatConversationsProvider.overrideWith(
              (ref) => Stream.value([conversation]),
            ),
            chatConversationMemoryProvider.overrideWith(
              (ref, conversationId) => memoryController.stream,
            ),
          ],
          child: const MaterialApp(
            home: ChatInfoPage(conversationId: 'chat_info_refresh'),
          ),
        ),
      ),
    );

    memoryController.add(
      ChatConversationMemory(
        conversationId: 'chat_info_refresh',
        summary: '旧摘要',
        facts: [oldFact],
        updatedAt: now,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.main.info.memoriesTab));
    await tester.pumpAndSettle();

    expect(find.text(t.main.info.memoriesTitle), findsWidgets);
    expect(find.text('旧事实'), findsOneWidget);

    memoryController.add(
      ChatConversationMemory(
        conversationId: 'chat_info_refresh',
        summary: '旧摘要',
        facts: [oldFact, newFact],
        updatedAt: now.add(const Duration(seconds: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.main.info.memoriesTitle), findsWidgets);
    expect(find.text('旧事实'), findsOneWidget);
    expect(find.text('新增事实'), findsOneWidget);
    expect(find.text(t.main.info.summaryLabel), findsNothing);
  });
}
