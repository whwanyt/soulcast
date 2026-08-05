part of 'chat.dart';

/// Chat notifier 的流式与非流式生成执行。
mixin _ChatGenerationDeliveryActions on _ChatGenerationPersistenceActions {
  /// 返回是否已按中断处理（调用方避免重复落盘）。
  Future<bool> _sendNormalResponse({
    required LlmClient client,
    required ChatSettings settings,
    required List<ChatConversationMessage> prefixMessages,
    required ChatConversationMemory memory,
    required ChatConversationMessage userMessage,
    required String conversationId,
    required Completer<void> abortCompleter,
    ChatConversationMessage? resumeAssistant,
    String? continueUserPrompt,
    String? seedRemoteResponseId,
    _AssistantRegenerateContext? regenerate,
    void Function(String remoteResponseId)? onRemoteResponseId,
  }) async {
    final imageMode = _shouldUseImageMode(
      userMessage: userMessage,
      continueUserPrompt: continueUserPrompt,
    );
    final completionResult = await ref
        .read(chatServiceProvider)
        .createCompletion(
          client: client,
          settings: settings,
          messages: prefixMessages,
          tools: _toolsForRequest(imageMode: imageMode),
          mcpTools: imageMode ? const [] : ref.read(mcpToolsProvider),
          mcpToolRunner: imageMode
              ? null
              : ref.read(mcpSessionManagerProvider.notifier),
          memory: memory,
          resumeAssistant: resumeAssistant,
          continueUserPrompt: continueUserPrompt,
          seedRemoteResponseId: seedRemoteResponseId,
          imageMode: imageMode,
          abortTrigger: abortCompleter.future,
          onRemoteResponseId: onRemoteResponseId,
        );

    final stablePrefix = _prefixWithoutResumeAssistant(
      prefixMessages,
      resumeAssistant,
    );
    final projected = _projectCompletionResult(
      completionResult,
      regenerate: regenerate,
      resumeAssistant: resumeAssistant,
    );

    if (abortCompleter.isCompleted || _abortCompleter != abortCompleter) {
      Log.d('Chat response ignored after abort', tag: 'Chat');
      await _persistInterruptedAssistant(
        conversationId,
        sourceMessages: [...stablePrefix, ...projected.messages],
      );
      return true;
    }

    await _finishSuccessfulCompletion(
      conversationId: conversationId,
      client: client,
      settings: settings,
      memory: memory,
      userMessage: userMessage,
      prefixMessages: stablePrefix,
      completionResult: completionResult,
      regenerate: regenerate,
      resumeAssistant: resumeAssistant,
    );
    return false;
  }

  /// 返回是否已按中断处理（调用方避免重复落盘）。
  Future<bool> _sendStreamingResponse({
    required LlmClient client,
    required ChatSettings settings,
    required List<ChatConversationMessage> prefixMessages,
    required ChatConversationMemory memory,
    required ChatConversationMessage userMessage,
    required String conversationId,
    required Completer<void> abortCompleter,
    ChatConversationMessage? resumeAssistant,
    String? continueUserPrompt,
    _AssistantRegenerateContext? regenerate,
    void Function(String remoteResponseId)? onRemoteResponseId,
  }) async {
    ChatCompletionResult? finalResult;
    final stablePrefix = _prefixWithoutResumeAssistant(
      prefixMessages,
      resumeAssistant,
    );
    var lastPartsSignature = '';

    final imageMode = _shouldUseImageMode(
      userMessage: userMessage,
      continueUserPrompt: continueUserPrompt,
    );
    await for (final completionResult
        in ref
            .read(chatServiceProvider)
            .createCompletionStream(
              client: client,
              settings: settings,
              messages: prefixMessages,
              tools: _toolsForRequest(imageMode: imageMode),
              mcpTools: imageMode ? const [] : ref.read(mcpToolsProvider),
              mcpToolRunner: imageMode
                  ? null
                  : ref.read(mcpSessionManagerProvider.notifier),
              memory: memory,
              resumeAssistant: resumeAssistant,
              continueUserPrompt: continueUserPrompt,
              imageMode: imageMode,
              abortTrigger: abortCompleter.future,
              onRemoteResponseId: onRemoteResponseId,
            )) {
      final projected = _projectCompletionResult(
        completionResult,
        regenerate: regenerate,
        resumeAssistant: resumeAssistant,
      );
      final nextMessages = [...stablePrefix, ...projected.messages];
      if (abortCompleter.isCompleted || _abortCompleter != abortCompleter) {
        // 先写入本帧内容，再标记中断，避免停在更早的一帧。
        _applyFocusedMessages(
          conversationId: conversationId,
          messages: nextMessages,
          lastUsage: projected.lastUsage,
        );
        Log.d('Chat streaming response ignored after abort', tag: 'Chat');
        await _persistInterruptedAssistant(
          conversationId,
          sourceMessages: nextMessages,
        );
        return true;
      }

      finalResult = completionResult;
      _applyFocusedMessages(
        conversationId: conversationId,
        messages: nextMessages,
        lastUsage: projected.lastUsage,
      );

      final partsSignature = projected.messages
          .map((message) => '${message.id}:${message.parts.length}')
          .join(',');
      final structureChanged = partsSignature != lastPartsSignature;
      lastPartsSignature = partsSignature;
      await _maybeCheckpointAssistant(
        conversationId: conversationId,
        assistantMessages: projected.messages,
        force: structureChanged,
      );
    }

    if (abortCompleter.isCompleted ||
        _abortCompleter != abortCompleter ||
        finalResult == null) {
      Log.d('Chat streaming response ignored after abort', tag: 'Chat');
      await _persistInterruptedAssistant(conversationId);
      return true;
    }

    await _finishSuccessfulCompletion(
      conversationId: conversationId,
      client: client,
      settings: settings,
      memory: memory,
      userMessage: userMessage,
      prefixMessages: stablePrefix,
      completionResult: finalResult,
      regenerate: regenerate,
      resumeAssistant: resumeAssistant,
    );
    return false;
  }
}
