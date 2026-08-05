import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/prompts/prompt_edit_page.dart';
import 'package:soulcast/pages/prompts/prompts_list_page.dart';
import 'package:soulcast/pages/settings/settings_page.dart';
import 'package:soulcast/shared/prompt/prompt.dart';

void main() {
  testWidgets('Settings page exposes chat response mode selector', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const ProviderScope(child: MaterialApp(home: SettingsPage())),
      ),
    );
    await tester.pump();

    expect(find.text(t.settings.prompts), findsOneWidget);
    expect(find.text(t.settings.modelSettings), findsOneWidget);

    // ListView 懒构建，响应方式在列表下部，需滚入视口后再断言。
    await tester.scrollUntilVisible(
      find.text(t.settings.responseMode),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(t.settings.responseMode), findsOneWidget);
    expect(find.text(t.settings.responseStream), findsOneWidget);
  });

  testWidgets('Prompts list and edit pages expose configurable templates', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const ProviderScope(child: MaterialApp(home: PromptsListPage())),
      ),
    );
    await tester.pump();

    expect(find.text(t.prompts.listTitle), findsOneWidget);
    expect(find.text(t.prompts.items.appSystem.title), findsOneWidget);

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          child: MaterialApp(
            home: PromptEditPage(promptId: PromptId.appSystem.storageKey),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(t.prompts.items.appSystem.title), findsOneWidget);
    expect(find.text(t.prompts.fieldLabel), findsOneWidget);
    expect(find.text(t.prompts.defaults.appSystem), findsWidgets);
    expect(find.text(t.prompts.restoreDefault), findsOneWidget);
  });
}
