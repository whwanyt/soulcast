import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/chat/service/chat_title_prompt_builder.dart';

void main() {
  group('canAutoGenerateChatConversationTitle', () {
    test('only pending allows auto generation', () {
      expect(
        canAutoGenerateChatConversationTitle(
          ChatConversationTitleOrigin.pending,
        ),
        isTrue,
      );
      expect(
        canAutoGenerateChatConversationTitle(
          ChatConversationTitleOrigin.generated,
        ),
        isFalse,
      );
      expect(
        canAutoGenerateChatConversationTitle(
          ChatConversationTitleOrigin.manual,
        ),
        isFalse,
      );
    });
  });

  group('sanitizeGeneratedChatConversationTitle', () {
    test('strips quotes newlines and collapses whitespace', () {
      expect(
        sanitizeGeneratedChatConversationTitle('"浮城真相调查"\n补充说明'),
        '浮城真相调查',
      );
      expect(sanitizeGeneratedChatConversationTitle('「星轨  航行」'), '星轨 航行');
    });

    test('truncates long titles', () {
      final title = sanitizeGeneratedChatConversationTitle(
        '这是一个非常非常非常非常非常非常非常长的会话标题内容',
      );
      expect(title, isNotNull);
      expect(title!.endsWith('...'), isTrue);
      expect(title.length, lessThanOrEqualTo(27));
    });

    test('rejects empty or default titles', () {
      expect(sanitizeGeneratedChatConversationTitle('   '), isNull);
      expect(sanitizeGeneratedChatConversationTitle('新会话'), isNull);
      expect(sanitizeGeneratedChatConversationTitle('""'), isNull);
    });
  });

  group('buildChatTitleUpdatePrompt', () {
    test('includes truncated user and assistant content', () async {
      final prompt = await buildChatTitleUpdatePrompt(
        userMessage: ChatConversationMessage.user('用户想了解浮城为何坠落'),
        assistantMessage: ChatConversationMessage.assistant(
          content: '浮城依靠星轨维持高度，坠落可能与星轨断裂有关。',
        ),
        template:
            '请根据以下对话，为会话生成一个简短标题。\n\n'
            '规则：\n4. 不要输出 Markdown、解释或多余文字，只输出标题本身。\n\n'
            '用户消息：\n{{userText}}\n\n助手回复：\n{{assistantText}}',
      );

      expect(prompt, contains('用户想了解浮城为何坠落'));
      expect(prompt, contains('浮城依靠星轨维持高度'));
      expect(prompt, contains('只输出标题本身'));
    });
  });
}
