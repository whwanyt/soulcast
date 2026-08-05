import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/shared/prompt/prompt.dart';

const chatTitlePromptUserMaxLength = 400;
const chatTitlePromptAssistantMaxLength = 400;

/// 构造基于首轮用户与助手消息生成简短标题的提示词。
Future<String> buildChatTitleUpdatePrompt({
  required ChatConversationMessage userMessage,
  required ChatConversationMessage assistantMessage,
  required String template,
  String? fallbackTemplate,
}) {
  final userText = _limitText(
    userMessage.content.trim(),
    chatTitlePromptUserMaxLength,
  );
  final assistantText = _limitText(
    assistantMessage.content.trim(),
    chatTitlePromptAssistantMaxLength,
  );

  return renderPromptTemplate(template, {
    PromptTokenNames.userText: userText,
    PromptTokenNames.assistantText: assistantText,
  }, fallbackTemplate: fallbackTemplate);
}

String _limitText(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength)}...';
}
