part of 'chat_service.dart';

/// 构造发送给模型的系统提示词与裁剪后历史消息。
Future<List<LlmMessage>> buildLlmRequestMessages({
  required ChatSettings settings,
  required List<ChatConversationMessage> messages,
  ChatConversationMemory? memory,
}) async {
  final cardSystemPrompt = settings.cardSystemPrompt?.trim();
  final loreBeforeChar = settings.loreBeforeChar?.trim();
  final characterPrompt = settings.characterPrompt?.trim();
  final loreAfterChar = settings.loreAfterChar?.trim();
  final systemPrompt = settings.systemPrompt?.trim();
  final postHistoryInstructions = settings.postHistoryInstructions?.trim();
  final memoryTemplate = settings.memoryInjectTemplate?.trim();
  final memoryPrompt =
      memory == null || memoryTemplate == null || memoryTemplate.isEmpty
      ? null
      : await buildChatMemorySystemPrompt(
          memory,
          template: memoryTemplate,
          fallbackTemplate: settings.memoryInjectFallbackTemplate,
        );
  final contextMessages = limitContextMessages(
    messages,
    settings.maxContextMessages,
  );
  final history = <LlmMessage>[];
  for (final message in contextMessages) {
    history.addAll(await expandConversationMessageToLlm(message));
  }
  return [
    if (cardSystemPrompt != null && cardSystemPrompt.isNotEmpty)
      LlmMessage.system(cardSystemPrompt),
    if (loreBeforeChar != null && loreBeforeChar.isNotEmpty)
      LlmMessage.system(loreBeforeChar),
    if (characterPrompt != null && characterPrompt.isNotEmpty)
      LlmMessage.system(characterPrompt),
    if (loreAfterChar != null && loreAfterChar.isNotEmpty)
      LlmMessage.system(loreAfterChar),
    if (systemPrompt != null && systemPrompt.isNotEmpty)
      LlmMessage.system(systemPrompt),
    if (memoryPrompt != null && memoryPrompt.trim().isNotEmpty)
      LlmMessage.system(memoryPrompt),
    ...history,
    if (postHistoryInstructions != null && postHistoryInstructions.isNotEmpty)
      LlmMessage.system(postHistoryInstructions),
  ];
}

/// 仅保留最近 [maxCount] 条历史消息；[maxCount] 为 `null` 时不截断。
List<ChatConversationMessage> limitContextMessages(
  List<ChatConversationMessage> messages,
  int? maxCount,
) {
  if (maxCount == null || maxCount <= 0 || messages.length <= maxCount) {
    return messages;
  }
  return messages.sublist(messages.length - maxCount);
}
