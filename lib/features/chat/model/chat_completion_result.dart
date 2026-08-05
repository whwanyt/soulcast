import 'package:soulcast/entities/chat/chat.dart';

/// 一轮聊天编排完成后的消息列表与终止原因摘要。
class ChatCompletionResult {
  const ChatCompletionResult({
    required this.messages,
    this.isToolCallsExceeded = false,
  });

  final List<ChatConversationMessage> messages;
  final bool isToolCallsExceeded;

  ChatConversationMessage? get lastAssistantMessage {
    for (final message in messages.reversed) {
      if (message.role == ChatConversationRole.assistant) {
        return message;
      }
    }
    return null;
  }

  ChatUsageSnapshot? get lastUsage => lastAssistantMessage?.usage;
}
