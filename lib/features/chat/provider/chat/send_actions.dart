part of 'chat.dart';

/// Chat notifier 的发送、续写、中止与清错入口。
mixin _ChatSendActions on _ChatGenerationSettings {
  Future<void> sendMessage(String content) async {
    final text = content.trim();
    final draftAttachments = List<ChatAttachmentPart>.from(
      state.draftAttachments,
    );
    if (text.isEmpty && draftAttachments.isEmpty) {
      Log.d('Skip sending empty chat message', tag: 'Chat');
      return;
    }
    if (state.isSending) {
      Log.d(
        'Skip sending chat message because another request is active',
        tag: 'Chat',
      );
      return;
    }

    _clearErrorMessage();
    if (state.selectedModelId == null) {
      Log.d('Chat send blocked: missing selected model', tag: 'Chat');
      state = state.copyWith(errorMessage: t.chat.error.missingModel);
      return;
    }
    if (ChatCreateImageMention.contains(text) && !_hasConfiguredImageModel()) {
      Log.d('Chat send blocked: missing image model', tag: 'Chat');
      state = state.copyWith(
        errorMessage: t.agent.generateImage.missingImageModelResult,
      );
      return;
    }

    final hasImageAttachment = draftAttachments.any((part) => part.isImage);
    if (hasImageAttachment && !await _selectedModelSupportsImageInput()) {
      Log.d(
        'Chat send warning: selected model lacks image input format',
        tag: 'Chat',
      );
      SmartDialog.showToast(t.chat.error.modelNoImageInput);
    }

    final conversationId = await _ensureSelectedConversationId();
    if (conversationId == null) {
      return;
    }

    try {
      await _ensureDocumentsReadable(draftAttachments);
    } on ChatAttachmentImportException catch (error) {
      state = state.copyWith(errorMessage: _chatAttachmentErrorMessage(error));
      return;
    }

    final userMessage = ChatConversationMessage.user(
      text,
      parts: draftAttachments,
    );
    final pendingMessages = [...state.messages, userMessage];
    await _saveMessages(conversationId, [userMessage]);
    await _saveDraftMessage(conversationId, '');
    Log.d(
      'Chat send started: messageId=${userMessage.id}, '
      'inputLength=${text.length}, attachments=${draftAttachments.length}, '
      'history=${state.messages.length}',
      tag: 'Chat',
    );
    state = state.copyWith(
      messages: pendingMessages,
      draftMessage: '',
      draftAttachments: const [],
      errorMessage: null,
    );

    await _runAssistantGeneration(
      conversationId: conversationId,
      prefixMessages: pendingMessages,
      userMessage: userMessage,
      resumeAssistant: null,
      continueUserPrompt: null,
      regenerate: null,
    );
  }

  Future<void> _ensureDocumentsReadable(
    List<ChatAttachmentPart> attachments,
  ) async {
    final importer = ChatAttachmentImporter();
    for (final part in attachments) {
      if (!part.isDocument) {
        continue;
      }
      await importer.readDocumentText(part);
    }
  }

  Future<void> continueReply() async {
    if (state.isSending) {
      Log.d(
        'Skip continue reply because another request is active',
        tag: 'Chat',
      );
      return;
    }

    _clearErrorMessage();
    final turn = _resolveLastAssistantTurn(state.messages);
    if (turn == null) {
      Log.d('Skip continue reply: missing last assistant turn', tag: 'Chat');
      return;
    }

    final remoteResponseId = turn.assistant.remoteResponseId?.trim();
    if (remoteResponseId != null && remoteResponseId.isNotEmpty) {
      Log.d(
        'Chat continue reply prefers remote resume: '
        'messageId=${turn.assistant.id}',
        tag: 'Chat',
      );
      await resumePendingRemoteResponse();
      return;
    }

    if (!turn.assistant.isInterrupted) {
      Log.d(
        'Skip continue reply: last message is not interrupted',
        tag: 'Chat',
      );
      return;
    }

    final conversationId = state.selectedConversationId;
    if (conversationId == null) {
      return;
    }

    final userMessage = turn.userMessage;
    final last = turn.assistant;
    final resumeAssistant =
        (last.versions.isEmpty ? last.withSyncedSingleVersion() : last)
            .copyWith(isInterrupted: false);
    final prefixMessages = [
      ...state.messages.sublist(0, turn.assistantIndex),
      resumeAssistant,
    ];
    Log.d(
      'Chat continue reply started: messageId=${resumeAssistant.id}',
      tag: 'Chat',
    );
    state = state.copyWith(messages: prefixMessages, errorMessage: null);

    await _runAssistantGeneration(
      conversationId: conversationId,
      prefixMessages: prefixMessages,
      userMessage: userMessage,
      resumeAssistant: resumeAssistant,
      continueUserPrompt: t.chat.continuePrompt,
      regenerate: null,
    );
  }

  @override
  Future<void> resumePendingRemoteResponse() async {
    if (state.isSending) {
      return;
    }

    final conversationId = state.selectedConversationId;
    if (conversationId == null) {
      return;
    }

    final turn = _resolveLastAssistantTurn(state.messages);
    if (turn == null) {
      return;
    }

    final remoteResponseId = turn.assistant.remoteResponseId?.trim();
    if (remoteResponseId == null || remoteResponseId.isEmpty) {
      return;
    }
    if (turn.assistant.finishReason != null) {
      return;
    }

    final resumeAssistant =
        (turn.assistant.versions.isEmpty
                ? turn.assistant.withSyncedSingleVersion()
                : turn.assistant)
            .copyWith(isInterrupted: false);
    final prefixMessages = [
      ...state.messages.sublist(0, turn.assistantIndex),
      resumeAssistant,
    ];
    Log.d(
      'Chat resume pending remote response: messageId=${resumeAssistant.id}, '
      'remoteResponseId=$remoteResponseId',
      tag: 'Chat',
    );
    state = state.copyWith(messages: prefixMessages, errorMessage: null);

    await _runAssistantGeneration(
      conversationId: conversationId,
      prefixMessages: prefixMessages,
      userMessage: turn.userMessage,
      resumeAssistant: resumeAssistant,
      continueUserPrompt: null,
      regenerate: null,
    );
  }

  void cancelSending() {
    if (!state.isSending) {
      return;
    }
    Log.d('Chat send cancel requested', tag: 'Chat');
    _abortRequest();
  }

  void clearError() {
    _clearErrorMessage();
  }

  @override
  void _clearErrorMessage() {
    if (state.errorMessage == null) {
      return;
    }
    Log.d('Chat error cleared', tag: 'Chat');
    state = state.copyWith(errorMessage: null);
  }
}
