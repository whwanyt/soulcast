part of 'chat_service.dart';

/// 非流式完成编排：循环处理模型回复与工具调用直到正文完成。
mixin _ChatCompletion on _ChatToolLoop, _ChatImageMode {
  Future<ChatCompletionResult> createCompletion({
    required LlmClient client,
    required ChatSettings settings,
    required List<ChatConversationMessage> messages,
    required List<AgentTool> tools,
    List<McpRemoteTool> mcpTools = const [],
    McpToolRunner? mcpToolRunner,
    ChatConversationMemory? memory,
    ChatConversationMessage? resumeAssistant,
    String? continueUserPrompt,
    String? seedRemoteResponseId,
    bool imageMode = false,
    Future<void>? abortTrigger,
    void Function(String remoteResponseId)? onRemoteResponseId,
  }) async {
    if (imageMode) {
      // 图片模式只走图像模型 createImage，不请求聊天模型 / tool_choice。
      return _createDirectImageCompletion(
        tools: tools,
        messages: messages,
        resumeAssistant: resumeAssistant,
        continueUserPrompt: continueUserPrompt,
        abortTrigger: abortTrigger,
      );
    }

    var requestMessages = await _buildRequestMessages(
      settings: settings,
      messages: messages,
      memory: memory,
      continueUserPrompt: continueUserPrompt,
    );
    final trimmedSeed = seedRemoteResponseId?.trim();
    final hasSeed = trimmedSeed != null && trimmedSeed.isNotEmpty;
    var response = hasSeed
        ? await _pollRemoteResponseUntilComplete(
            client: client,
            remoteResponseId: trimmedSeed,
            abortTrigger: abortTrigger,
          )
        : await _createChatCompletion(
            client: client,
            settings: settings,
            messages: requestMessages,
            tools: tools,
            mcpTools: mcpTools,
            abortTrigger: abortTrigger,
            onRemoteResponseId: onRemoteResponseId,
          );
    final turnId = resumeAssistant?.id ?? _createTurnId();
    var committedParts = hasSeed
        ? _seedPartsForRemoteResume(resumeAssistant)
        : _seedCommittedParts(resumeAssistant);
    final roundBase = _nextRoundIndex(committedParts);
    ChatConversationMessage? turnMessage = resumeAssistant == null
        ? null
        : _buildAssistantTurn(
            turnId: turnId,
            current: resumeAssistant,
            parts: committedParts,
          );
    final maxToolRounds = settings.maxToolRounds;

    for (
      var round = 0;
      maxToolRounds == null || round < maxToolRounds;
      round++
    ) {
      final roundIndex = roundBase + round;
      final toolCalls = response.toolCalls;
      final roundParts = _partsFromCompletion(
        response: response,
        turnId: turnId,
        round: roundIndex,
        allowEmptyText: toolCalls.isNotEmpty,
      );

      if (toolCalls.isEmpty) {
        committedParts = [
          ...committedParts,
          ..._sanitizeTextPartsWhenImagePresent(
            roundParts,
            hasReadyImage: _hasReadyImagePart(committedParts),
          ),
        ];
        turnMessage = _buildAssistantTurn(
          turnId: turnId,
          current: turnMessage,
          parts: committedParts,
          finishReason: response.finishReason,
          completionId: response.id,
          usage: _resolveUsage(response.usage),
        );
        return ChatCompletionResult(messages: [turnMessage]);
      }

      Log.d(
        'Chat tool calls requested: round=${round + 1}, '
        'count=${toolCalls.length}',
        tag: 'Chat',
      );
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
        finishReason: response.finishReason,
        completionId: response.id,
        usage: _resolveUsage(response.usage),
      );
      requestMessages = [
        ...requestMessages,
        LlmMessage.assistant(
          content: response.message?.content,
          refusal: response.message?.refusal,
          toolCalls: toolCalls,
        ),
        ...toolResults.map((result) => result.apiMessage),
      ];
      response = await _createChatCompletion(
        client: client,
        settings: settings,
        messages: requestMessages,
        tools: tools,
        mcpTools: mcpTools,
        abortTrigger: abortTrigger,
        onRemoteResponseId: onRemoteResponseId,
      );
    }

    Log.d('Chat tool calls exceeded max rounds', tag: 'Chat');
    committedParts = [
      ...committedParts,
      ChatTextPart(
        id: '${turnId}_exceeded',
        content: t.chat.error.toolCallsExceeded,
      ),
    ];
    return ChatCompletionResult(
      messages: [
        _buildAssistantTurn(
          turnId: turnId,
          current: turnMessage,
          parts: committedParts,
          completionId: response.id,
          usage: _resolveUsage(response.usage),
        ),
      ],
      isToolCallsExceeded: true,
    );
  }
}
