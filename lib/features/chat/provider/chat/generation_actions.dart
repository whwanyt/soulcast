part of 'chat.dart';

/// Chat notifier 的生成生命周期协调与占位消息准备。
mixin _ChatGenerationActions on _ChatGenerationDeliveryActions {
  @override
  Future<void> _runAssistantGeneration({
    required String conversationId,
    required List<ChatConversationMessage> prefixMessages,
    required ChatConversationMessage userMessage,
    required ChatConversationMessage? resumeAssistant,
    required String? continueUserPrompt,
    required _AssistantRegenerateContext? regenerate,
  }) async {
    final selectedModelId = state.selectedModelId;
    if (selectedModelId == null) {
      Log.d('Chat send blocked: missing selected model', tag: 'Chat');
      state = state.copyWith(errorMessage: t.chat.error.missingModel);
      return;
    }

    final settings = await _resolveChatSettings(
      modelId: selectedModelId,
      conversationId: conversationId,
    );
    if (settings == null) {
      final errorMessage = state.errorMessage;
      final lastRole = state.messages.isEmpty ? null : state.messages.last.role;
      // 用户消息已落库但尚未开始生成时，补一条错误助手消息，避免只剩用户气泡。
      if (errorMessage != null &&
          errorMessage.isNotEmpty &&
          lastRole == ChatConversationRole.user) {
        await _presentGenerationFailure(
          conversationId: conversationId,
          errorMessage: errorMessage,
        );
      }
      return;
    }

    final memory = await _loadMemory(conversationId);
    final abortCompleter = Completer<void>();
    _abortCompleter = abortCompleter;
    _activeRegenerate = regenerate;
    _activeRunConversationId = conversationId;
    _lastStreamCheckpointAt = null;
    final client = createLlmClient(settings);

    final placeholder = await _prepareGeneratingAssistant(
      conversationId: conversationId,
      prefixMessages: prefixMessages,
      resumeAssistant: resumeAssistant,
      regenerate: regenerate,
    );
    _activePlaceholderAssistant = placeholder;

    void onRemoteResponseId(String remoteResponseId) {
      unawaited(
        _checkpointRemoteResponseId(
          conversationId: conversationId,
          remoteResponseId: remoteResponseId,
        ),
      );
    }

    var finalizedAsInterrupted = false;
    try {
      // 续写重发带 continueUserPrompt，不用 remote id 取回；取回仅走 poll + tool loop。
      final trimmedSeed =
          (continueUserPrompt == null || continueUserPrompt.trim().isEmpty)
          ? resumeAssistant?.remoteResponseId?.trim()
          : null;
      final hasSeed = trimmedSeed != null && trimmedSeed.isNotEmpty;
      final responseMode = ref.read(appPreferencesProvider).responseMode;
      // 取回路径走非流式：先 poll 再进入同一套 tool loop / finish。
      if (!hasSeed && responseMode == ChatResponseModePreference.stream) {
        finalizedAsInterrupted = await _sendStreamingResponse(
          client: client,
          settings: settings,
          prefixMessages: prefixMessages,
          memory: memory,
          userMessage: userMessage,
          conversationId: conversationId,
          abortCompleter: abortCompleter,
          resumeAssistant: resumeAssistant,
          continueUserPrompt: continueUserPrompt,
          regenerate: regenerate,
          onRemoteResponseId: onRemoteResponseId,
        );
      } else {
        finalizedAsInterrupted = await _sendNormalResponse(
          client: client,
          settings: settings,
          prefixMessages: prefixMessages,
          memory: memory,
          userMessage: userMessage,
          conversationId: conversationId,
          abortCompleter: abortCompleter,
          resumeAssistant: resumeAssistant,
          continueUserPrompt: continueUserPrompt,
          regenerate: regenerate,
          seedRemoteResponseId: trimmedSeed,
          onRemoteResponseId: onRemoteResponseId,
        );
      }
    } catch (error, stackTrace) {
      // abortTrigger 可能抛出 LlmAbortedException，也可能是底层 HTTP 取消异常。
      final aborted =
          abortCompleter.isCompleted || error is LlmAbortedException;
      if (aborted) {
        Log.d('Chat send aborted: $error', tag: 'Chat');
        if (!finalizedAsInterrupted) {
          await _persistInterruptedAssistant(conversationId);
        }
      } else if (error is LlmException) {
        Log.e(
          'Chat send failed: ${error.message}',
          tag: 'Chat',
          error: error,
          stackTrace: stackTrace,
        );
        await _presentGenerationFailure(
          conversationId: conversationId,
          errorMessage: error.message,
        );
      } else {
        Log.e(
          'Chat send failed unexpectedly: $error',
          tag: 'Chat',
          error: error,
          stackTrace: stackTrace,
        );
        await _presentGenerationFailure(
          conversationId: conversationId,
          errorMessage: error.toString(),
        );
      }
    } finally {
      // 用户中止时先 cancel 服务端 background 任务，再 close client。
      if (abortCompleter.isCompleted) {
        final remoteResponseId = _activePlaceholderAssistant?.remoteResponseId
            ?.trim();
        if (remoteResponseId != null && remoteResponseId.isNotEmpty) {
          try {
            Log.d(
              'Chat cancelling remote response: '
              'remoteResponseId=$remoteResponseId',
              tag: 'Chat',
            );
            await client.cancelRemoteResponse(remoteResponseId);
          } catch (error, stackTrace) {
            Log.e(
              'Chat cancel remote response failed: $error',
              tag: 'Chat',
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
      }
      client.close();
      if (_abortCompleter == abortCompleter) {
        _abortCompleter = null;
      }
      // 流正常结束但已触发 abort 时，确保中断态落盘。
      if (abortCompleter.isCompleted &&
          _activeRunConversationId == conversationId &&
          !finalizedAsInterrupted) {
        await _persistInterruptedAssistant(conversationId);
      }
      if (_activeRegenerate == regenerate) {
        _activeRegenerate = null;
      }
      if (_activeRunConversationId == conversationId) {
        _activeRunConversationId = null;
        _activePlaceholderAssistant = null;
        _lastStreamCheckpointAt = null;
      }
    }
  }

  /// 生成开始即落库占位助手，保证中途退出仍有时间线。
  Future<ChatConversationMessage> _prepareGeneratingAssistant({
    required String conversationId,
    required List<ChatConversationMessage> prefixMessages,
    required ChatConversationMessage? resumeAssistant,
    required _AssistantRegenerateContext? regenerate,
  }) async {
    if (resumeAssistant != null) {
      await _saveMessages(conversationId, [resumeAssistant]);
      if (_isConversationFocused(conversationId)) {
        state = state.copyWith(isSending: true, errorMessage: null);
      }
      return resumeAssistant;
    }

    final ChatConversationMessage placeholder;
    if (regenerate != null) {
      placeholder = ChatConversationMessage(
        id: regenerate.turnId,
        role: ChatConversationRole.assistant,
        content: '',
        createdAt: regenerate.createdAt,
        parts: const [],
      ).withSyncedSingleVersion();
    } else {
      placeholder = ChatConversationMessage.assistant(content: '');
    }

    await _saveMessages(conversationId, [placeholder]);
    if (_isConversationFocused(conversationId)) {
      state = state.copyWith(
        messages: [...prefixMessages, placeholder],
        isSending: true,
        errorMessage: null,
      );
    }
    Log.d(
      'Chat generating assistant prepared: messageId=${placeholder.id}',
      tag: 'Chat',
    );
    return placeholder;
  }
}
