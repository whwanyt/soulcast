import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/widgets/agent_chat/agent_chat.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('Agent chat list renders role-specific messages', (tester) async {
    final messages = [
      ChatConversationMessage.user('你好'),
      ChatConversationMessage.assistant(
        content: '现在是下午。',
        parts: const [
          ChatToolCallPart(
            id: 'call_time',
            toolCallId: 'call_time',
            toolName: AgentToolIds.currentTime,
            status: ChatToolCallPartStatus.completed,
            result: '{"utcIso8601":"2026-07-03T08:00:00.000Z"}',
          ),
          ChatToolCallPart(
            id: 'call_location',
            toolCallId: 'call_location',
            toolName: AgentToolIds.currentLocation,
            status: ChatToolCallPartStatus.completed,
            result:
                '{"status":"success","latitude":31.2304,'
                '"longitude":121.4737}',
          ),
          ChatTextPart(id: 't1', content: '现在是下午。'),
        ],
      ),
    ];

    await tester.pumpWidget(_agentChatListHarness(messages));

    final translations = t;
    expect(
      _findTextInFlutterList(
        '${translations.chat.role.tool}: ${AgentToolIds.currentTime} · '
        '${translations.chat.toolCall.completed}',
      ),
      findsOneWidget,
    );
    expect(
      _findTextInFlutterList(translations.chat.role.assistant),
      findsWidgets,
    );
    expect(
      _findTextInFlutterList(
        '${translations.chat.role.tool}: ${AgentToolIds.currentLocation} · '
        '${translations.chat.toolCall.completed}',
      ),
      findsOneWidget,
    );
    expect(_findTextInFlutterList('你好'), findsOneWidget);
    expect(
      _findTextInFlutterList('{"utcIso8601":"2026-07-03T08:00:00.000Z"}'),
      findsNothing,
    );
    await tester.tap(
      _findTextInFlutterList(
        '${translations.chat.role.tool}: ${AgentToolIds.currentTime} · '
        '${translations.chat.toolCall.completed}',
      ),
    );
    await tester.pump();
    expect(
      _findTextInFlutterList('{"utcIso8601":"2026-07-03T08:00:00.000Z"}'),
      findsOneWidget,
    );
    await tester.tap(
      _findTextInFlutterList(
        '${translations.chat.role.tool}: ${AgentToolIds.currentLocation} · '
        '${translations.chat.toolCall.completed}',
      ),
    );
    await tester.pump();
    expect(
      _findTextInFlutterList(
        '{"status":"success","latitude":31.2304,'
        '"longitude":121.4737}',
      ),
      findsOneWidget,
    );
    expect(_findTextInFlutterList('现在是下午。'), findsOneWidget);
  });

  testWidgets('Agent chat list rerenders assistant message updates', (
    tester,
  ) async {
    final message = ChatConversationMessage.assistant(content: '正在生成');

    await tester.pumpWidget(_agentChatListHarness([message]));

    expect(_findTextInFlutterList('正在生成'), findsOneWidget);

    await tester.pumpWidget(
      _agentChatListHarness([
        message.copyWith(
          content: '正在生成完整回答',
          parts: [ChatTextPart(id: '${message.id}-text', content: '正在生成完整回答')],
        ),
      ]),
    );

    expect(_findTextInFlutterList('正在生成'), findsNothing);
    expect(_findTextInFlutterList('正在生成完整回答'), findsOneWidget);
  });

  testWidgets('Agent chat list renders assistant reasoning content', (
    tester,
  ) async {
    final message = ChatConversationMessage.assistant(
      content: '最终回答',
      parts: const [
        ChatReasoningPart(id: 'r1', content: '先分析问题，再给出结论。'),
        ChatTextPart(id: 't1', content: '最终回答'),
      ],
    );

    await tester.pumpWidget(_agentChatListHarness([message]));

    expect(_findTextInFlutterList(t.chat.reasoningTitle), findsOneWidget);
    expect(_findTextInFlutterList('先分析问题，再给出结论。'), findsNothing);
    expect(_findTextInFlutterList('最终回答'), findsOneWidget);

    await tester.tap(_findTextInFlutterList(t.chat.reasoningTitle));
    await tester.pump();

    expect(_findTextInFlutterList('先分析问题，再给出结论。'), findsOneWidget);
  });

  testWidgets('Agent chat shows continue reply on interrupted last message', (
    tester,
  ) async {
    var continued = false;
    final message = ChatConversationMessage.assistant(
      content: '半截回复',
      isInterrupted: true,
      parts: const [ChatTextPart(id: 't1', content: '半截回复')],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: AgentChatMessageList(
                messages: [message],
                onContinueReply: () => continued = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(_findTextInFlutterList(t.chat.continueReply), findsOneWidget);
    await tester.tap(_findTextInFlutterList(t.chat.continueReply));
    await tester.pump();
    expect(continued, isTrue);

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: AgentChatMessageList(
                messages: [message, ChatConversationMessage.user('新问题')],
                onContinueReply: () => continued = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(_findTextInFlutterList(t.chat.continueReply), findsNothing);
  });

  testWidgets('Agent chat expands active reasoning while sending', (
    tester,
  ) async {
    final message = ChatConversationMessage.assistant(
      content: '',
      parts: const [ChatReasoningPart(id: 'r1', content: '流式思考中')],
    );

    await tester.pumpWidget(_agentChatListHarness([message], isSending: true));

    expect(_findTextInFlutterList('流式思考中'), findsOneWidget);

    await tester.pumpWidget(_agentChatListHarness([message], isSending: false));
    await tester.pump();

    expect(_findTextInFlutterList('流式思考中'), findsNothing);
  });

  testWidgets('Agent chat list renders assistant turn parts timeline', (
    tester,
  ) async {
    final message = ChatConversationMessage.assistant(
      content: '最终回答',
      parts: const [
        ChatReasoningPart(id: 'r1', content: '调用工具前的思考'),
        ChatToolCallPart(
          id: 'call_1',
          toolCallId: 'call_1',
          toolName: AgentToolIds.currentTime,
          status: ChatToolCallPartStatus.completed,
          result: '{"ok":true}',
        ),
        ChatTextPart(id: 't1', content: '最终回答'),
      ],
    );

    await tester.pumpWidget(_agentChatListHarness([message]));

    expect(_findTextInFlutterList(t.chat.reasoningTitle), findsOneWidget);
    expect(
      _findTextInFlutterList(
        '${t.chat.role.tool}: ${AgentToolIds.currentTime} · '
        '${t.chat.toolCall.completed}',
      ),
      findsOneWidget,
    );
    expect(_findTextInFlutterList('最终回答'), findsOneWidget);
    expect(_findTextInFlutterList('调用工具前的思考'), findsNothing);

    await tester.tap(_findTextInFlutterList(t.chat.reasoningTitle));
    await tester.pump();
    expect(_findTextInFlutterList('调用工具前的思考'), findsOneWidget);
  });

  testWidgets('Agent chat markdown headings keep app body font size', (
    tester,
  ) async {
    final message = ChatConversationMessage.assistant(
      content: '# 主题标题\n\n普通内容',
    );

    await tester.pumpWidget(_agentChatListHarness([message]));

    final titleText = _findTextInFlutterList('主题标题');
    expect(titleText, findsOneWidget);

    final titleWidget = tester.widget<Text>(titleText);
    final bodySize = Theme.of(
      tester.element(titleText),
    ).textTheme.bodyLarge?.fontSize;
    expect(_textSpanStyle(titleWidget.textSpan, '主题标题')?.fontSize, bodySize);
  });

  testWidgets('Agent chat markdown tables render flat custom layout', (
    tester,
  ) async {
    final message = ChatConversationMessage.assistant(
      content: '| 名称 | 数量 |\n| --- | --- |\n| 苹果 | 3 |\n| 香蕉 | 5 |',
    );

    await tester.pumpWidget(_agentChatListHarness([message]));

    expect(_findTextInFlutterList('名称'), findsOneWidget);
    expect(_findTextInFlutterList('苹果'), findsOneWidget);
    expect(_findTextInFlutterList('香蕉'), findsOneWidget);
    expect(find.byType(Table, skipOffstage: false), findsOneWidget);
  });

  testWidgets('Agent chat markdown flat styles cover common blocks', (
    tester,
  ) async {
    final message = ChatConversationMessage.assistant(
      content:
          '> 引用内容\n\n'
          '- 无序列表\n'
          '1. 有序列表\n\n'
          '内联 `code` 与代码块：\n\n'
          '```dart\nprint(1);\n```\n\n'
          '[链接](https://example.com)',
    );

    await tester.pumpWidget(_agentChatListHarness([message]));

    expect(_findTextInFlutterList('引用内容'), findsOneWidget);
    expect(_findTextInFlutterList('无序列表'), findsOneWidget);
    expect(_findTextInFlutterList('有序列表'), findsOneWidget);
    expect(_findTextInFlutterList('code'), findsOneWidget);
    expect(_findTextInFlutterList('dart'), findsOneWidget);
    expect(
      find.textContaining('print(1);', skipOffstage: false),
      findsOneWidget,
    );
    expect(_findTextInFlutterList('链接'), findsOneWidget);
  });

  testWidgets('Agent chat list pauses following and returns to bottom', (
    tester,
  ) async {
    final messages = List.generate(
      30,
      (index) => ChatConversationMessage.assistant(
        content: '历史消息 $index\n第二行内容用于撑开高度',
      ),
    );

    await tester.pumpWidget(_agentChatListHarness(messages));
    await tester.pumpAndSettle();

    expect(_findTextInFlutterList('历史消息 29\n第二行内容用于撑开高度'), findsOneWidget);
    expect(find.text(t.chat.scrollToBottom), findsNothing);

    await tester.drag(find.byType(AgentChatMessageList), const Offset(0, 300));
    await tester.pump();

    expect(find.text(t.chat.scrollToBottom), findsOneWidget);

    await tester.tap(find.text(t.chat.scrollToBottom));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text(t.chat.scrollToBottom), findsNothing);
    expect(_findTextInFlutterList('历史消息 29\n第二行内容用于撑开高度'), findsOneWidget);
  });

  testWidgets('Agent chat list follows bottom when keyboard opens', (
    tester,
  ) async {
    final messages = List.generate(
      30,
      (index) => ChatConversationMessage.assistant(
        content: '键盘消息 $index\n第二行内容用于撑开高度',
      ),
    );

    Widget buildList({required double bottomInset}) {
      return ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  viewInsets: EdgeInsets.only(bottom: bottomInset),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 600 - bottomInset,
                    child: AgentChatMessageList(messages: messages),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildList(bottomInset: 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(AgentChatMessageList), const Offset(0, 300));
    await tester.pump();

    expect(find.text(t.chat.scrollToBottom), findsOneWidget);

    await tester.pumpWidget(buildList(bottomInset: 320));
    await tester.pumpAndSettle();

    expect(find.text(t.chat.scrollToBottom), findsNothing);
    expect(_findTextInFlutterList('键盘消息 29\n第二行内容用于撑开高度'), findsOneWidget);
  });
}

Widget _agentChatListHarness(
  List<ChatConversationMessage> messages, {
  bool isSending = false,
}) {
  return ProviderScope(
    child: TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: AgentChatMessageList(messages: messages, isSending: isSending),
        ),
      ),
    ),
  );
}

Finder _findTextInFlutterList(String text) {
  return find.text(text, skipOffstage: false);
}

TextStyle? _textSpanStyle(InlineSpan? span, String text) {
  if (span is TextSpan) {
    if (span.text == text) {
      return span.style;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      final style = _textSpanStyle(child, text);
      if (style != null) {
        return style;
      }
    }
  }
  return null;
}
