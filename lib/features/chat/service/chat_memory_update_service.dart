import 'dart:convert';

import 'package:flute_core/log/log.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/agent/llm.dart';
import 'package:soulcast/shared/prompt/prompt.dart';

import 'chat_memory_prompt_builder.dart';

/// 调用 LLM 整理会话长期记忆，并将结构化结果解析为领域模型。
class ChatMemoryUpdateService {
  const ChatMemoryUpdateService();

  Future<ChatConversationMemory?> updateMemory({
    required LlmClient client,
    required ChatSettings settings,
    required ChatConversationMemory memory,
    required ChatConversationMessage userMessage,
    required ChatConversationMessage assistantMessage,
    required String systemTemplate,
    required String userTemplate,
    String? systemFallbackTemplate,
    String? userFallbackTemplate,
  }) async {
    try {
      final systemPrompt = await renderPromptTemplate(
        systemTemplate,
        const {},
        fallbackTemplate: systemFallbackTemplate,
      );
      final userPrompt = await buildChatMemoryUpdatePrompt(
        memory: memory,
        userMessage: userMessage,
        assistantMessage: assistantMessage,
        template: userTemplate,
        fallbackTemplate: userFallbackTemplate,
      );
      final response = await client.createChatCompletion(
        LlmChatRequest(
          model: settings.model,
          messages: [
            LlmMessage.system(systemPrompt),
            LlmMessage.user(userPrompt),
          ],
          temperature: 0,
          maxTokens: 1200,
          responseFormat: LlmResponseFormat.jsonObject,
        ),
      );

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        Log.w('Chat memory update skipped: empty response', tag: 'Chat');
        return null;
      }

      return parseChatMemoryUpdate(
        conversationId: memory.conversationId,
        source: text,
      );
    } catch (error, stackTrace) {
      Log.e(
        'Chat memory update failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

/// 解析记忆整理器返回的 JSON；无效响应返回 `null`。
ChatConversationMemory? parseChatMemoryUpdate({
  required String conversationId,
  required String source,
  DateTime? fallbackNow,
}) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      return null;
    }

    final now = fallbackNow ?? DateTime.now();
    final summary = decoded['summary'] is String
        ? (decoded['summary'] as String).trim()
        : '';
    final factsSource = decoded['facts'];
    final facts = factsSource is List
        ? factsSource
              .whereType<Map>()
              .map(
                (item) =>
                    _factFromUpdateJson(item.cast<String, dynamic>(), now),
              )
              .where((fact) => fact.content.trim().isNotEmpty)
              .toList()
        : const <ChatMemoryFact>[];

    return ChatConversationMemory(
      conversationId: conversationId,
      summary: summary,
      facts: facts,
      updatedAt: now,
    );
  } catch (error, stackTrace) {
    Log.e(
      'Chat memory update parse failed: $error',
      tag: 'Chat',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

ChatMemoryFact _factFromUpdateJson(Map<String, dynamic> json, DateTime now) {
  final parsed = ChatMemoryFact.fromJson(json);
  final createdAt = DateTime.tryParse('${json['createdAt']}') ?? now;
  final updatedAt = DateTime.tryParse('${json['updatedAt']}') ?? now;
  return parsed.copyWith(
    id: parsed.id.trim().isEmpty ? createChatMemoryFactId(now) : parsed.id,
    content: parsed.content.trim(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
