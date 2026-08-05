part of 'chat_service.dart';

/// 聊天请求消息与工具定义构造。
mixin _ChatRequestBuilder on _ChatImageResultMapper {
  List<LlmToolDefinition> _toolDefinitions({
    required List<AgentTool> tools,
    required List<McpRemoteTool> mcpTools,
  }) {
    return [
      ...tools.map((tool) => tool.definition),
      ...mcpTools.map(
        (tool) => LlmToolDefinition(
          name: tool.qualifiedName,
          description: tool.description,
          parameters: tool.parameters,
        ),
      ),
    ];
  }

  Future<List<LlmMessage>> _buildRequestMessages({
    required ChatSettings settings,
    required List<ChatConversationMessage> messages,
    ChatConversationMemory? memory,
    String? continueUserPrompt,
  }) async {
    final requestMessages = await buildLlmRequestMessages(
      settings: settings,
      messages: messages,
      memory: memory,
    );
    final prompt = continueUserPrompt?.trim();
    if (prompt == null || prompt.isEmpty) {
      return requestMessages;
    }
    return [...requestMessages, LlmMessage.user(prompt)];
  }
}
