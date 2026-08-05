import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/main/widget/main_chat_drawer.dart';
import 'package:soulcast/pages/main/widget/main_chat_top_bar.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('Main chat drawer long press shows conversation actions', (
    tester,
  ) async {
    String? selectedConversationId;
    (String, bool)? pinChange;
    (String, String)? renamedConversation;
    String? deletedConversationId;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: MainChatDrawer(
              conversations: AsyncData([
                ChatConversationEntity(
                  id: 'chat_menu',
                  title: '置顶测试',
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ]),
              selectedConversationId: null,
              isEnabled: true,
              onSelected: (conversationId) {
                selectedConversationId = conversationId;
              },
              onNewConversation: () {},
              onPinChanged: (conversationId, isPinned) {
                pinChange = (conversationId, isPinned);
              },
              onRenamed: (conversationId, title) async {
                renamedConversation = (conversationId, title);
              },
              onDeleted: (conversationId) {
                deletedConversationId = conversationId;
              },
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('置顶测试'));
    await tester.pumpAndSettle();

    expect(find.text(t.main.conversationMenu.pin), findsOneWidget);
    expect(find.text(t.main.conversationMenu.rename), findsOneWidget);
    expect(find.text(t.main.conversationMenu.delete), findsOneWidget);

    await tester.tap(find.text(t.main.conversationMenu.pin));
    await tester.pumpAndSettle();

    expect(pinChange, ('chat_menu', true));
    expect(selectedConversationId, isNull);

    await tester.longPress(find.text('置顶测试'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.main.conversationMenu.rename));
    await tester.pumpAndSettle();

    expect(find.text(t.main.renameConversation.title), findsOneWidget);
    expect(find.text(t.main.renameConversation.fieldLabel), findsOneWidget);

    await tester.enterText(find.byType(TextField), '新的会话标题');
    await tester.tap(find.text(t.main.renameConversation.save));
    await tester.pumpAndSettle();

    expect(renamedConversation, ('chat_menu', '新的会话标题'));

    await tester.longPress(find.text('置顶测试'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.main.conversationMenu.delete));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.main.conversationMenu.deleteConfirm));
    await tester.pumpAndSettle();

    expect(deletedConversationId, 'chat_menu');
  });

  testWidgets('Main chat top bar keeps menu and info actions', (tester) async {
    var infoPressed = false;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: MainChatTopBar(
              isInfoEnabled: true,
              onMenuPressed: () {},
              onInfoPressed: () {
                infoPressed = true;
              },
            ),
          ),
        ),
      ),
    );

    final header = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('main_chat_header_gradient')),
    );
    final decoration = header.decoration as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    final colorScheme = Theme.of(
      tester.element(find.byType(MainChatTopBar)),
    ).colorScheme;
    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(gradient.colors.first, colorScheme.surfaceContainerLow);
    expect(
      gradient.colors.last,
      colorScheme.surfaceContainerLow.withValues(alpha: 0),
    );

    await tester.tap(find.byTooltip(t.main.info.title));
    await tester.pump();
    expect(infoPressed, isTrue);
    expect(find.byTooltip('GPT-4o mini'), findsNothing);
    expect(find.byTooltip(t.main.newConversation), findsNothing);
  });
}
