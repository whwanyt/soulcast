import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/agent/api/llm_client.dart';
import 'package:soulcast/features/agent/model/chat_settings.dart';
import 'package:soulcast/features/agent/model/llm_chat_completion.dart';
import 'package:soulcast/features/agent/model/llm_chat_request.dart';
import 'package:soulcast/features/agent/model/llm_image_generation.dart';
import 'package:soulcast/features/agent/model/llm_image_request.dart';
import 'package:soulcast/features/agent/model/llm_message.dart';
import 'package:soulcast/features/agent/model/llm_remote_poll_result.dart';
import 'package:soulcast/features/agent/model/llm_stream_snapshot.dart';
import 'package:soulcast/features/agent/model/remote_ai_model.dart';
import 'package:soulcast/features/chat/service/chat_memory_prompt_builder.dart';
import 'package:soulcast/features/chat/service/chat_memory_update_service.dart';
import 'package:soulcast/features/chat/service/chat_service.dart';
import 'package:soulcast/features/agent/service/remote_ai_model_service.dart';

void main() {
  test('Chat memory facts encode and decode JSON', () {
    final fact = ChatMemoryFact(
      id: 'fact_role',
      category: ChatMemoryFactCategory.relationship,
      content: '主角是失忆的占星师。',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    final encoded = encodeChatMemoryFacts([fact]);
    final decoded = decodeChatMemoryFacts(encoded);

    expect(decoded, hasLength(1));
    expect(decoded.first.id, 'fact_role');
    expect(decoded.first.category, ChatMemoryFactCategory.relationship);
    expect(decoded.first.content, '主角是失忆的占星师。');
  });

  test('Chat memory update parser accepts summary and facts', () {
    final memory = parseChatMemoryUpdate(
      conversationId: 'chat_memory',
      fallbackNow: DateTime.utc(2026, 1, 3),
      source: '''
{
  "summary": "角色正在追查浮城坠落的真相。",
  "facts": [
    {
      "id": "fact_world",
      "category": "worldSetting",
      "content": "七座浮城依靠星轨维持高度。"
    }
  ]
}
''',
    );

    expect(memory, isNotNull);
    expect(memory!.summary, '角色正在追查浮城坠落的真相。');
    expect(memory.facts, hasLength(1));
    expect(memory.facts.first.category, ChatMemoryFactCategory.worldSetting);
    expect(memory.facts.first.content, '七座浮城依靠星轨维持高度。');
    expect(memory.facts.first.createdAt, DateTime.utc(2026, 1, 3));
  });

  test(
    'Chat memory system prompt includes summary and limited facts',
    () async {
      final memory = ChatConversationMemory(
        conversationId: 'chat_prompt',
        summary: '这是一段会话摘要。',
        facts: [
          ChatMemoryFact(
            id: 'fact_1',
            category: ChatMemoryFactCategory.worldSetting,
            content: '世界由七座浮城组成。',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ],
        updatedAt: DateTime.utc(2026),
      );

      final prompt = await buildChatMemorySystemPrompt(
        memory,
        template:
            '以下是当前会话的长期记忆，只用于理解本会话上下文；不要主动复述，除非用户询问。\n\n'
            '摘要：\n{{summary}}\n\n长期事实：\n{{facts}}',
      );
      expect(prompt, contains('摘要'));
      expect(prompt, contains('这是一段会话摘要。'));
      expect(prompt, contains('worldSetting'));
      expect(prompt, contains('世界由七座浮城组成。'));
    },
  );

  test('LLM request messages insert memory after system prompt', () async {
    final messages = await buildLlmRequestMessages(
      settings: const ChatSettings(
        apiKey: 'key',
        baseUrl: 'https://example.com/v1',
        timeout: Duration(seconds: 30),
        connectTimeout: Duration(seconds: 10),
        maxRetries: 1,
        model: 'gpt-test',
        systemPrompt: '系统提示词',
        memoryInjectTemplate:
            '以下是当前会话的长期记忆，只用于理解本会话上下文；不要主动复述，除非用户询问。\n\n'
            '摘要：\n{{summary}}\n\n长期事实：\n{{facts}}',
      ),
      memory: ChatConversationMemory(
        conversationId: 'chat_order',
        summary: '长期记忆摘要',
        facts: const [],
        updatedAt: DateTime.utc(2026),
      ),
      messages: [
        ChatConversationMessage.user('你好'),
        ChatConversationMessage.memory(content: '{"ignored":true}'),
      ],
    );

    expect(messages, hasLength(3));
    expect(messages[0].role, LlmMessageRole.system);
    expect(messages[0].content, '系统提示词');
    expect(messages[1].role, LlmMessageRole.system);
    expect(messages[1].content, contains('长期记忆摘要'));
    expect(messages[2].role, LlmMessageRole.user);
  });

  test('Chat settings joins base URL and API path', () {
    const settings = ChatSettings(
      apiKey: 'key',
      baseUrl: 'https://api.deepseek.com/',
      apiPath: '/v1/',
      timeout: Duration(seconds: 30),
      connectTimeout: Duration(seconds: 10),
      maxRetries: 1,
      model: 'deepseek-chat',
    );

    expect(settings.apiBaseUrl, 'https://api.deepseek.com/v1');
    expect(
      settings.copyWith(apiPath: '').apiBaseUrl,
      'https://api.deepseek.com',
    );
  });

  test('Remote AI model parses provider model JSON', () {
    final model = RemoteAiModel.fromJson({
      'id': ' deepseek-v4-flash ',
      'object': 'model',
      'owned_by': 'deepseek',
    });

    expect(model.id, 'deepseek-v4-flash');
    expect(model.object, 'model');
    expect(model.ownedBy, 'deepseek');
  });

  test('Remote AI model service normalizes base URL for models endpoint', () {
    expect(
      normalizeRemoteModelBaseUrl('https://api.deepseek.com/'),
      'https://api.deepseek.com',
    );
  });

  test('Remote AI model service maps listModels from LlmClient', () async {
    final service = RemoteAiModelService(
      clientFactory: ({required String apiKey, required String baseUrl}) =>
          _FakeLlmClient(
            models: const [
              RemoteAiModel(
                id: 'deepseek-v4-pro',
                object: 'model',
                ownedBy: 'deepseek',
              ),
              RemoteAiModel(
                id: 'deepseek-v4-flash',
                object: 'model',
                ownedBy: 'deepseek',
              ),
            ],
          ),
    );

    final models = await service.fetchModels(
      baseUrl: 'https://api.deepseek.com/',
      apiKey: 'TOKEN',
    );

    expect(models.map((model) => model.id), [
      'deepseek-v4-pro',
      'deepseek-v4-flash',
    ]);
    expect(models.first.ownedBy, 'deepseek');
  });
}

class _FakeLlmClient implements LlmClient {
  _FakeLlmClient({required this.models});

  final List<RemoteAiModel> models;
  var closed = false;

  @override
  Future<LlmChatCompletion> createChatCompletion(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<LlmStreamSnapshot> createChatCompletionStream(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LlmImageGeneration> createImage(LlmImageRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<LlmRemotePollResult> pollRemoteResponse(
    String remoteResponseId, {
    Future<void>? abortTrigger,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelRemoteResponse(
    String remoteResponseId, {
    Future<void>? abortTrigger,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<RemoteAiModel>> listModels() async => models;

  @override
  void close() {
    closed = true;
  }
}
