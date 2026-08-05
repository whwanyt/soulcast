import 'package:flute_core/log/log.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/agent/llm.dart';
import 'package:soulcast/shared/prompt/prompt.dart';

import 'chat_title_prompt_builder.dart';

/// 调用 LLM 为待命名会话生成并清洗短标题。
class ChatTitleUpdateService {
  const ChatTitleUpdateService();

  Future<String?> generateTitle({
    required LlmClient client,
    required ChatSettings settings,
    required ChatConversationMessage userMessage,
    required ChatConversationMessage assistantMessage,
    required String systemTemplate,
    required String userTemplate,
    String? systemFallbackTemplate,
    String? userFallbackTemplate,
  }) async {
    final userText = userMessage.content.trim();
    final assistantText = assistantMessage.content.trim();
    if (userText.isEmpty && assistantText.isEmpty) {
      Log.d('Chat title update skipped: empty messages', tag: 'Chat');
      return null;
    }

    try {
      final systemPrompt = await renderPromptTemplate(
        systemTemplate,
        const {},
        fallbackTemplate: systemFallbackTemplate,
      );
      final userPrompt = await buildChatTitleUpdatePrompt(
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
          maxTokens: 48,
        ),
      );

      final sanitized = sanitizeGeneratedChatConversationTitle(response.text);
      if (sanitized == null) {
        Log.w(
          'Chat title update skipped: empty or invalid response',
          tag: 'Chat',
        );
        return null;
      }
      return sanitized;
    } catch (error, stackTrace) {
      Log.e(
        'Chat title update failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
