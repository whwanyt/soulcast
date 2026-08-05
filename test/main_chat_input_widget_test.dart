import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nf_extended_text_field/nf_extended_text_field.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/main/widget/main_chat_input.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('Main chat input shows stop while sending', (tester) async {
    var stopped = false;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: MainChatInput(
              enabled: true,
              isSending: true,
              draftMessage: '边生成边输入',
              onDraftChanged: (_) {},
              onSubmitted: (_) {},
              onStopPressed: () => stopped = true,
              onToolsPressed: () {},
              onMcpPressed: () {},
              modelLabel: 'GPT-4o mini',
              onModelPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip(t.main.input.stop), findsOneWidget);
    expect(find.byTooltip(t.main.input.send), findsNothing);
    expect(
      tester.widget<ExtendedTextField>(find.byType(ExtendedTextField)).enabled,
      isTrue,
    );

    await tester.tap(find.byTooltip(t.main.input.stop));
    await tester.pump();
    expect(stopped, isTrue);
  });

  testWidgets('Main chat input preserves and emits draft changes', (
    tester,
  ) async {
    final drafts = <String>[];

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: MainChatInput(
              enabled: true,
              isSending: false,
              draftMessage: '旧草稿',
              onDraftChanged: drafts.add,
              onSubmitted: (_) {},
              onStopPressed: () {},
              onToolsPressed: () {},
              onMcpPressed: () {},
              modelLabel: 'GPT-4o mini',
              onModelPressed: () {},
            ),
          ),
        ),
      ),
    );

    ExtendedTextField field() {
      return tester.widget<ExtendedTextField>(find.byType(ExtendedTextField));
    }

    expect(field().controller?.text, '旧草稿');

    field().controller?.text = '新草稿';
    await tester.pump();
    expect(drafts.last, '新草稿');

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: MainChatInput(
              enabled: true,
              isSending: false,
              draftMessage: '另一个会话草稿',
              onDraftChanged: drafts.add,
              onSubmitted: (_) {},
              onStopPressed: () {},
              onToolsPressed: () {},
              onMcpPressed: () {},
              modelLabel: 'GPT-4o mini',
              onModelPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(field().controller?.text, '另一个会话草稿');
  });

  testWidgets('Main chat input moves above actions after wrapping', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 280,
                child: MainChatInput(
                  enabled: true,
                  isSending: false,
                  draftMessage: '短文本',
                  onDraftChanged: (_) {},
                  onSubmitted: (_) {},
                  onStopPressed: () {},
                  onToolsPressed: () {},
                  onMcpPressed: () {},
                  modelLabel: 'GPT-4o mini',
                  onModelPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final textField = find.byType(ExtendedTextField);
    final addButton = find.byTooltip(t.main.input.add);
    final toolButton = find.byTooltip(t.main.toolPanel.open);
    final sendButton = find.byTooltip(t.main.input.send);

    expect(
      tester.getBottomLeft(textField).dy,
      lessThan(tester.getTopLeft(addButton).dy),
    );
    expect(
      tester.getBottomLeft(textField).dy,
      lessThan(tester.getTopLeft(toolButton).dy),
    );
    expect(
      tester.getBottomLeft(textField).dy,
      lessThan(tester.getTopLeft(sendButton).dy),
    );

    tester.widget<ExtendedTextField>(textField).controller?.text =
        '这是一段会自动换行的长文本，用来验证输入框会移动到两个按钮的上方。';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(
      tester.getBottomLeft(textField).dy,
      lessThan(tester.getTopLeft(addButton).dy),
    );
    expect(
      tester.getBottomLeft(textField).dy,
      lessThan(tester.getTopLeft(sendButton).dy),
    );
  });

  testWidgets('Main chat input button unfocuses before submit', (tester) async {
    String? submittedText;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: MainChatInput(
              enabled: true,
              isSending: false,
              draftMessage: '准备发送',
              onDraftChanged: (_) {},
              onSubmitted: (value) {
                submittedText = value;
              },
              onStopPressed: () {},
              onToolsPressed: () {},
              onMcpPressed: () {},
              modelLabel: 'GPT-4o mini',
              onModelPressed: () {},
            ),
          ),
        ),
      ),
    );

    final textField = find.byType(ExtendedTextField);
    final input = tester.widget<ExtendedTextField>(textField);
    input.focusNode?.requestFocus();
    await tester.pump();

    expect(input.focusNode?.hasFocus, isTrue);

    await tester.tap(find.byTooltip(t.main.input.send));
    await tester.pump();

    expect(submittedText, '准备发送');
    expect(input.focusNode?.hasFocus, isFalse);
  });

  testWidgets('Main chat input exposes tool and model actions below input', (
    tester,
  ) async {
    var toolsPressed = false;
    var mcpPressed = false;
    var modelPressed = false;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: MainChatInput(
              enabled: true,
              isSending: false,
              draftMessage: '',
              onDraftChanged: (_) {},
              onSubmitted: (_) {},
              onStopPressed: () {},
              onToolsPressed: () {
                toolsPressed = true;
              },
              onMcpPressed: () {
                mcpPressed = true;
              },
              modelLabel: 'GPT-4o mini',
              onModelPressed: () {
                modelPressed = true;
              },
            ),
          ),
        ),
      ),
    );

    final textField = find.byType(ExtendedTextField);
    final addButton = find.byTooltip(t.main.input.add);
    final toolButton = find.byTooltip(t.main.toolPanel.open);
    final mcpButton = find.byTooltip(t.main.mcpPanel.open);
    final modelButton = find.byTooltip('GPT-4o mini');
    final sendButton = find.byTooltip(t.main.input.send);
    expect(
      tester.getBottomLeft(textField).dy,
      lessThan(tester.getTopLeft(toolButton).dy),
    );
    expect(
      tester.getBottomLeft(textField).dy,
      lessThan(tester.getTopLeft(modelButton).dy),
    );
    expect(
      tester.getTopRight(addButton).dx,
      lessThan(tester.getTopLeft(toolButton).dx),
    );
    expect(
      tester.getTopRight(toolButton).dx,
      lessThan(tester.getTopLeft(mcpButton).dx),
    );
    expect(
      tester.getTopRight(mcpButton).dx,
      lessThan(tester.getTopLeft(modelButton).dx),
    );
    expect(tester.getSize(addButton), const Size.square(36));
    expect(tester.getSize(toolButton), const Size.square(36));
    expect(tester.getSize(mcpButton), const Size.square(36));
    expect(tester.getSize(modelButton), const Size.square(36));
    expect(tester.getSize(sendButton), const Size.square(36));

    await tester.tap(toolButton);
    await tester.tap(mcpButton);
    await tester.tap(modelButton);
    expect(toolsPressed, isTrue);
    expect(mcpPressed, isTrue);
    expect(modelPressed, isTrue);
  });
}
