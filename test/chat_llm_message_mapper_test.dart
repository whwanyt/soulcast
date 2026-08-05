import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/agent/api/openai_llm_mapper.dart';
import 'package:soulcast/features/agent/model/chat_settings.dart';
import 'package:soulcast/features/agent/model/llm_message.dart';
import 'package:soulcast/features/chat/service/chat_llm_message_mapper.dart';
import 'package:soulcast/features/chat/service/chat_service.dart';

void main() {
  test('expandConversationMessageToLlm skips reasoning and memory', () async {
    final assistant = ChatConversationMessage.assistant(
      content: '最终回答',
      parts: const [
        ChatReasoningPart(id: 'r1', content: '先想清楚'),
        ChatTextPart(id: 't1', content: '最终回答'),
      ],
    );
    final memory = ChatConversationMessage.memory(content: '{"summary":"x"}');

    final assistantMessages = await expandConversationMessageToLlm(assistant);
    expect(assistantMessages, hasLength(1));
    expect(assistantMessages.single.role, LlmMessageRole.assistant);
    expect(assistantMessages.single.content, '最终回答');

    expect(await expandConversationMessageToLlm(memory), isEmpty);
  });

  test(
    'expandConversationMessageToLlm replays tool rounds from parts',
    () async {
      final assistant = ChatConversationMessage.assistant(
        content: '现在是下午。',
        parts: const [
          ChatReasoningPart(id: 'r1', content: '需要查时间'),
          ChatToolCallPart(
            id: 'call_1',
            toolCallId: 'call_1',
            toolName: 'get_current_time',
            status: ChatToolCallPartStatus.completed,
            arguments: '{}',
            result: '{"hour":15}',
          ),
          ChatToolCallPart(
            id: 'call_2',
            toolCallId: 'call_2',
            toolName: 'get_current_location',
            status: ChatToolCallPartStatus.failed,
            arguments: '{}',
            result: '{"error":"denied"}',
          ),
          ChatTextPart(id: 't1', content: '现在是下午。'),
        ],
      );

      final messages = await expandConversationMessageToLlm(assistant);
      expect(messages, hasLength(4));

      final toolAssistant = messages[0];
      expect(toolAssistant.role, LlmMessageRole.assistant);
      expect(toolAssistant.content, isNull);
      expect(toolAssistant.toolCalls, hasLength(2));
      expect(toolAssistant.toolCalls![0].id, 'call_1');
      expect(toolAssistant.toolCalls![0].name, 'get_current_time');
      expect(toolAssistant.toolCalls![0].arguments, '{}');
      expect(toolAssistant.toolCalls![1].id, 'call_2');

      final tool1 = messages[1];
      expect(tool1.role, LlmMessageRole.tool);
      expect(tool1.toolCallId, 'call_1');
      expect(tool1.content, '{"hour":15}');

      final tool2 = messages[2];
      expect(tool2.role, LlmMessageRole.tool);
      expect(tool2.toolCallId, 'call_2');
      expect(tool2.content, '{"error":"denied"}');

      final finalAssistant = messages[3];
      expect(finalAssistant.role, LlmMessageRole.assistant);
      expect(finalAssistant.content, '现在是下午。');
      expect(finalAssistant.toolCalls, isNull);
    },
  );

  test(
    'expandConversationMessageToLlm includes ready ChatImagePart as markdown',
    () async {
      final assistant = ChatConversationMessage.assistant(
        content: '已生成图片',
        parts: const [
          ChatImagePart(
            id: 'img1',
            status: ChatImagePartStatus.ready,
            url: 'https://example.com/a.png',
          ),
          ChatTextPart(id: 't1', content: '一只猫'),
        ],
      );

      final messages = await expandConversationMessageToLlm(assistant);
      expect(messages, hasLength(1));
      expect(
        messages.single.content,
        '![generated image](https://example.com/a.png)\n\n一只猫',
      );
    },
  );

  test('expandConversationMessageToLlm skips running tool parts', () async {
    final assistant = ChatConversationMessage.assistant(
      content: '',
      parts: const [
        ChatToolCallPart(
          id: 'call_1',
          toolCallId: 'call_1',
          toolName: 'get_current_time',
          status: ChatToolCallPartStatus.running,
          arguments: '{}',
        ),
        ChatTextPart(id: 't1', content: '占位'),
      ],
    );

    final messages = await expandConversationMessageToLlm(assistant);
    expect(messages, hasLength(1));
    expect(messages.single.role, LlmMessageRole.assistant);
    expect(messages.single.content, '占位');
  });

  test('expand user document attachment into text context', () async {
    final dir = await Directory.systemTemp.createTemp('soulcast_attach_');
    final file = File('${dir.path}/note.txt');
    await file.writeAsString('hello attachment');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    final user = ChatConversationMessage.user(
      '总结一下',
      parts: [
        ChatAttachmentPart(
          id: 'a1',
          kind: ChatAttachmentKind.document,
          fileName: 'note.txt',
          mimeType: 'text/plain',
          localPath: file.path,
        ),
      ],
    );

    final messages = await expandConversationMessageToLlm(user);
    expect(messages, hasLength(1));
    expect(messages.single.contentParts, isNull);
    expect(messages.single.content, contains('总结一下'));
    expect(messages.single.content, contains('note.txt'));
    expect(messages.single.content, contains('hello attachment'));
  });

  test('toOpenAiMessage maps multimodal contentParts', () {
    final message = LlmMessage.user(
      'what is this',
      contentParts: const [
        LlmTextContentPart('what is this'),
        LlmImageUrlContentPart('data:image/png;base64,abc'),
      ],
    );

    final openAi = toOpenAiMessage(message);
    final json = openAi.toJson();
    expect(json['role'], 'user');
    final content = json['content'];
    expect(content, isA<List>());
    expect(content, hasLength(2));
    expect(content[0]['type'], 'text');
    expect(content[1]['type'], 'image_url');
  });

  test('buildLlmRequestMessages includes replayed tool history', () async {
    final messages = await buildLlmRequestMessages(
      settings: const ChatSettings(
        apiKey: 'key',
        baseUrl: 'https://example.com/v1',
        timeout: Duration(seconds: 30),
        connectTimeout: Duration(seconds: 10),
        maxRetries: 1,
        model: 'gpt-test',
        systemPrompt: '系统提示词',
      ),
      messages: [
        ChatConversationMessage.user('几点了'),
        ChatConversationMessage.assistant(
          content: '三点',
          parts: const [
            ChatToolCallPart(
              id: 'call_1',
              toolCallId: 'call_1',
              toolName: 'get_current_time',
              status: ChatToolCallPartStatus.completed,
              arguments: '{}',
              result: '{"hour":15}',
            ),
            ChatTextPart(id: 't1', content: '三点'),
          ],
        ),
        ChatConversationMessage.user('再确认一次'),
      ],
    );

    expect(messages[0].role, LlmMessageRole.system);
    expect(messages[1].role, LlmMessageRole.user);
    expect(messages[2].role, LlmMessageRole.assistant);
    expect(messages[2].toolCalls, hasLength(1));
    expect(messages[3].role, LlmMessageRole.tool);
    expect(messages[4].role, LlmMessageRole.assistant);
    expect(messages[4].content, '三点');
    expect(messages[5].role, LlmMessageRole.user);
  });
}
