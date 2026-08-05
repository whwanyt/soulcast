part of 'chat_service.dart';

/// 本地 Agent 工具与远端 MCP 工具的统一执行循环。
mixin _ChatToolLoop on _ChatAssistantTurnMapper {
  Future<List<_ToolCallResult>> _runToolCalls(
    List<LlmToolCall> toolCalls, {
    required List<AgentTool> tools,
    required List<McpRemoteTool> mcpTools,
    required McpToolRunner? mcpToolRunner,
  }) async {
    final localRegistry = {for (final tool in tools) tool.name: tool};
    final mcpRegistry = {for (final tool in mcpTools) tool.qualifiedName: tool};
    return Future.wait(
      toolCalls.map((toolCall) async {
        final toolName = toolCall.name;
        final arguments = _encodeToolArguments(toolCall);
        final localTool = localRegistry[toolName];
        final mcpTool = mcpRegistry[toolName];

        if (localTool == null && mcpTool == null) {
          Log.w('Chat tool not found: name=$toolName', tag: 'Chat');
          final content = jsonEncode({
            'error': 'unknown_tool',
            'message': '${t.chat.error.unknownTool}: $toolName',
          });
          return _buildToolCallResult(
            toolCall: toolCall,
            toolName: toolName,
            arguments: arguments,
            content: content,
            status: ChatToolCallPartStatus.failed,
          );
        }

        try {
          Log.d(
            'Chat tool started: name=$toolName, callId=${toolCall.id}',
            tag: 'Chat',
          );
          final Map<String, dynamic> output;
          if (mcpTool != null) {
            final runner = mcpToolRunner;
            if (runner == null) {
              throw StateError('MCP tool runner is not available');
            }
            output = await runner.callTool(
              toolName,
              _readToolArguments(toolCall),
            );
          } else {
            output = await localTool!.run(_readToolArguments(toolCall));
          }
          Log.d(
            'Chat tool succeeded: name=$toolName, callId=${toolCall.id}',
            tag: 'Chat',
          );
          return _buildToolCallResult(
            toolCall: toolCall,
            toolName: toolName,
            arguments: arguments,
            content: jsonEncode(output),
            status: ChatToolCallPartStatus.completed,
          );
        } catch (error, stackTrace) {
          Log.e(
            'Chat tool failed: name=$toolName, callId=${toolCall.id}, '
            'error=$error',
            tag: 'Chat',
            error: error,
            stackTrace: stackTrace,
          );
          final content = jsonEncode({
            'error': 'tool_failed',
            'message': error.toString(),
          });
          return _buildToolCallResult(
            toolCall: toolCall,
            toolName: toolName,
            arguments: arguments,
            content: content,
            status: ChatToolCallPartStatus.failed,
          );
        }
      }),
    );
  }

  _ToolCallResult _buildToolCallResult({
    required LlmToolCall toolCall,
    required String toolName,
    required String? arguments,
    required String content,
    required ChatToolCallPartStatus status,
  }) {
    return _ToolCallResult(
      apiMessage: LlmMessage.tool(toolCallId: toolCall.id, content: content),
      part: ChatToolCallPart(
        id: toolCall.id,
        toolCallId: toolCall.id,
        toolName: toolName,
        status: status,
        arguments: arguments,
        result: content,
      ),
    );
  }
}
