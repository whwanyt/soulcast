part of 'chat_service.dart';

/// 流式完成编排：持续产出消息快照，并在模型请求时执行工具循环。
mixin _ChatCompletionStream on _ChatToolLoop, _ChatImageMode {
  Stream<ChatCompletionResult> createCompletionStream({
    required LlmClient client,
    required ChatSettings settings,
    required List<ChatConversationMessage> messages,
    required List<AgentTool> tools,
    List<McpRemoteTool> mcpTools = const [],
    McpToolRunner? mcpToolRunner,
    ChatConversationMemory? memory,
    ChatConversationMessage? resumeAssistant,
    String? continueUserPrompt,
    bool imageMode = false,
    Future<void>? abortTrigger,
    void Function(String remoteResponseId)? onRemoteResponseId,
  }) async* {
    if (imageMode) {
      // 图片模式只走图像模型 createImage，不请求聊天模型 / tool_choice。
      yield* _createDirectImageCompletionStream(
        tools: tools,
        messages: messages,
        resumeAssistant: resumeAssistant,
        continueUserPrompt: continueUserPrompt,
        abortTrigger: abortTrigger,
      );
      return;
    }

    var requestMessages = await _buildRequestMessages(
      settings: settings,
      messages: messages,
      memory: memory,
      continueUserPrompt: continueUserPrompt,
    );
    final turnId = resumeAssistant?.id ?? _createTurnId();
    var committedParts = _seedCommittedParts(resumeAssistant);
    final roundBase = _nextRoundIndex(committedParts);
    ChatConversationMessage? turnMessage = resumeAssistant == null
        ? null
        : _buildAssistantTurn(
            turnId: turnId,
            current: resumeAssistant,
            parts: committedParts,
          );
    if (turnMessage != null) {
      yield ChatCompletionResult(messages: [turnMessage]);
    }

    final maxToolRounds = settings.maxToolRounds;
    for (
      var round = 0;
      maxToolRounds == null || round < maxToolRounds;
      round++
    ) {
      final roundIndex = roundBase + round;
      LlmStreamSnapshot? snapshot;

      await for (final next in _createChatCompletionStream(
        client: client,
        settings: settings,
        messages: requestMessages,
        tools: tools,
        mcpTools: mcpTools,
        abortTrigger: abortTrigger,
        onRemoteResponseId: onRemoteResponseId,
      )) {
        snapshot = next;
        final roundParts = _sanitizeTextPartsWhenImagePresent(
          _partsFromStreamSnapshot(
            snapshot: next,
            turnId: turnId,
            round: roundIndex,
            allowEmptyText: next.toolCalls.isNotEmpty,
          ),
          hasReadyImage: _hasReadyImagePart(committedParts),
        );
        turnMessage = _buildAssistantTurn(
          turnId: turnId,
          current: turnMessage,
          parts: [...committedParts, ...roundParts],
          finishReason: next.finishReason,
          completionId: next.id,
          usage: _resolveUsage(next.usage),
        );
        yield ChatCompletionResult(messages: [turnMessage]);
      }

      final accumulator = snapshot;
      if (accumulator == null) {
        return;
      }

      final toolCalls = accumulator.toolCalls;
      final roundParts = _sanitizeTextPartsWhenImagePresent(
        _partsFromStreamSnapshot(
          snapshot: accumulator,
          turnId: turnId,
          round: roundIndex,
          allowEmptyText: toolCalls.isNotEmpty,
        ),
        hasReadyImage: _hasReadyImagePart(committedParts),
      );

      if (toolCalls.isEmpty) {
        committedParts = [...committedParts, ...roundParts];
        turnMessage = _buildAssistantTurn(
          turnId: turnId,
          current: turnMessage,
          parts: committedParts,
          finishReason: accumulator.finishReason,
          completionId: accumulator.id,
          usage: _resolveUsage(accumulator.usage),
        );
        yield ChatCompletionResult(messages: [turnMessage]);
        return;
      }

      Log.d(
        'Chat stream tool calls requested: round=${round + 1}, '
        'count=${toolCalls.length}',
        tag: 'Chat',
      );

      final runningToolParts = [
        for (final toolCall in toolCalls)
          ChatToolCallPart(
            id: toolCall.id,
            toolCallId: toolCall.id,
            toolName: toolCall.name,
            status: ChatToolCallPartStatus.running,
            arguments: _encodeToolArguments(toolCall),
          ),
      ];
      turnMessage = _buildAssistantTurn(
        turnId: turnId,
        current: turnMessage,
        parts: [...committedParts, ...roundParts, ...runningToolParts],
        finishReason: accumulator.finishReason,
        completionId: accumulator.id,
        usage: _resolveUsage(accumulator.usage),
      );
      yield ChatCompletionResult(messages: [turnMessage]);

      final toolResults = await _runToolCalls(
        toolCalls,
        tools: tools,
        mcpTools: mcpTools,
        mcpToolRunner: mcpToolRunner,
      );
      final imageParts = _imagePartsFromToolResults(
        toolResults: toolResults,
        turnId: turnId,
        round: roundIndex,
      );
      committedParts = [
        ...committedParts,
        ...roundParts,
        ...toolResults.map((result) => result.part),
        ...imageParts,
      ];
      turnMessage = _buildAssistantTurn(
        turnId: turnId,
        current: turnMessage,
        parts: committedParts,
        finishReason: accumulator.finishReason,
        completionId: accumulator.id,
        usage: _resolveUsage(accumulator.usage),
      );
      yield ChatCompletionResult(messages: [turnMessage]);

      final roundText = accumulator.content.trim();
      requestMessages = [
        ...requestMessages,
        LlmMessage.assistant(
          content: roundText.isEmpty ? null : roundText,
          toolCalls: toolCalls,
        ),
        ...toolResults.map((result) => result.apiMessage),
      ];
    }

    Log.d('Chat stream tool calls exceeded max rounds', tag: 'Chat');
    committedParts = [
      ...committedParts,
      ChatTextPart(
        id: '${turnId}_exceeded',
        content: t.chat.error.toolCallsExceeded,
      ),
    ];
    yield ChatCompletionResult(
      messages: [
        _buildAssistantTurn(
          turnId: turnId,
          current: turnMessage,
          parts: committedParts,
        ),
      ],
      isToolCallsExceeded: true,
    );
  }
}
