part of 'chat.dart';

/// 重新生成助手回复时保留的原消息版本上下文。
class _AssistantRegenerateContext {
  const _AssistantRegenerateContext({
    required this.turnId,
    required this.existingVersions,
    required this.createdAt,
  });

  final String turnId;
  final List<ChatAssistantMessageVersion> existingVersions;
  final DateTime createdAt;
}

/// 最近一个完整用户/助手轮次在消息列表中的定位结果。
class _LastAssistantTurn {
  const _LastAssistantTurn({
    required this.assistantIndex,
    required this.assistant,
    required this.userIndex,
    required this.userMessage,
  });

  final int assistantIndex;
  final ChatConversationMessage assistant;
  final int userIndex;
  final ChatConversationMessage userMessage;
}
