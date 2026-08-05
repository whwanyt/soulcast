part of 'chat_service.dart';

/// 图片模式：不经过聊天模型 tool_choice，直接调用图像模型 `createImage`。
mixin _ChatImageMode on _ChatAssistantTurnMapper {
  Future<ChatCompletionResult> _createDirectImageCompletion({
    required List<AgentTool> tools,
    required List<ChatConversationMessage> messages,
    ChatConversationMessage? resumeAssistant,
    String? continueUserPrompt,
    Future<void>? abortTrigger,
  }) async {
    await _throwIfAborted(abortTrigger);
    final turnId = resumeAssistant?.id ?? _createTurnId();
    final seedParts = _seedCommittedParts(resumeAssistant);
    final prompt = _resolveDirectImagePrompt(
      messages: messages,
      continueUserPrompt: continueUserPrompt,
    );
    final imagePart = await _runDirectImageGeneration(
      tools: tools,
      prompt: prompt,
      imagePartId: '${turnId}_img_direct',
      abortTrigger: abortTrigger,
    );
    final parts = [..._withoutPendingImageParts(seedParts), imagePart];
    return ChatCompletionResult(
      messages: [
        _buildAssistantTurn(
          turnId: turnId,
          current: resumeAssistant,
          parts: parts,
        ),
      ],
    );
  }

  Stream<ChatCompletionResult> _createDirectImageCompletionStream({
    required List<AgentTool> tools,
    required List<ChatConversationMessage> messages,
    ChatConversationMessage? resumeAssistant,
    String? continueUserPrompt,
    Future<void>? abortTrigger,
  }) async* {
    final turnId = resumeAssistant?.id ?? _createTurnId();
    var committedParts = _withoutPendingImageParts(
      _seedCommittedParts(resumeAssistant),
    );
    final pending = ChatImagePart(
      id: '${turnId}_img_pending',
      status: ChatImagePartStatus.generating,
    );
    var turnMessage = _buildAssistantTurn(
      turnId: turnId,
      current: resumeAssistant,
      parts: [...committedParts, pending],
    );
    yield ChatCompletionResult(messages: [turnMessage]);

    await _throwIfAborted(abortTrigger);
    final prompt = _resolveDirectImagePrompt(
      messages: messages,
      continueUserPrompt: continueUserPrompt,
    );
    final imagePart = await _runDirectImageGeneration(
      tools: tools,
      prompt: prompt,
      imagePartId: '${turnId}_img_direct',
      abortTrigger: abortTrigger,
    );
    committedParts = [...committedParts, imagePart];
    turnMessage = _buildAssistantTurn(
      turnId: turnId,
      current: turnMessage,
      parts: committedParts,
    );
    yield ChatCompletionResult(messages: [turnMessage]);
  }

  Future<ChatImagePart> _runDirectImageGeneration({
    required List<AgentTool> tools,
    required String prompt,
    required String imagePartId,
    Future<void>? abortTrigger,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return ChatImagePart(
        id: imagePartId,
        status: ChatImagePartStatus.failed,
        errorMessage: t.agent.generateImage.invalidArgumentsResult,
      );
    }

    final tool = _resolveGenerateImageTool(tools);
    if (tool == null) {
      return ChatImagePart(
        id: imagePartId,
        status: ChatImagePartStatus.failed,
        errorMessage: t.agent.generateImage.missingImageModelResult,
      );
    }

    try {
      Log.d(
        'Chat image mode direct createImage started: promptLength=${trimmed.length}',
        tag: 'Chat',
      );
      final output = await tool.run({'prompt': trimmed});
      await _throwIfAborted(abortTrigger);
      return _imagePartFromGenerateImageOutput(
        output: output,
        id: imagePartId,
        fallbackPrompt: trimmed,
      );
    } catch (error, stackTrace) {
      if (abortTrigger != null && await _isAbortCompleted(abortTrigger)) {
        rethrow;
      }
      Log.e(
        'Chat image mode direct createImage failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      return ChatImagePart(
        id: imagePartId,
        status: ChatImagePartStatus.failed,
        errorMessage: error.toString(),
      );
    }
  }

  AgentTool? _resolveGenerateImageTool(List<AgentTool> tools) {
    for (final tool in tools) {
      if (tool.name == AgentToolIds.generateImage) {
        return tool;
      }
    }
    return null;
  }

  String _resolveDirectImagePrompt({
    required List<ChatConversationMessage> messages,
    String? continueUserPrompt,
  }) {
    final continued = continueUserPrompt?.trim();
    if (continued != null && continued.isNotEmpty) {
      return continued;
    }

    String? userText;
    for (var index = messages.length - 1; index >= 0; index--) {
      final message = messages[index];
      if (message.role != ChatConversationRole.user) {
        continue;
      }
      final content = ChatCreateImageMention.strip(message.content);
      if (content.isEmpty) {
        continue;
      }
      userText = content;
      break;
    }
    if (userText == null) {
      return '';
    }

    final previousPrompt = _lastReadyImagePrompt(messages);
    if (previousPrompt == null ||
        previousPrompt.isEmpty ||
        previousPrompt == userText) {
      return userText;
    }
    // 连续改图：把上一张的提示词与本轮修改意图一并交给图像模型。
    return '$previousPrompt\n\nRevision: $userText';
  }

  String? _lastReadyImagePrompt(List<ChatConversationMessage> messages) {
    for (var index = messages.length - 1; index >= 0; index--) {
      final message = messages[index];
      if (message.role != ChatConversationRole.assistant) {
        continue;
      }
      for (final part in message.parts.reversed) {
        if (part is! ChatImagePart ||
            part.status != ChatImagePartStatus.ready) {
          continue;
        }
        final revised = part.revisedPrompt?.trim();
        if (revised != null && revised.isNotEmpty) {
          return revised;
        }
      }
      // 若无 revisedPrompt，回退到该图之前最近一条用户正文作为原提示。
      for (var userIndex = index - 1; userIndex >= 0; userIndex--) {
        final previous = messages[userIndex];
        if (previous.role != ChatConversationRole.user) {
          continue;
        }
        final content = ChatCreateImageMention.strip(previous.content);
        if (content.isNotEmpty) {
          return content;
        }
      }
    }
    return null;
  }

  ChatImagePart _imagePartFromGenerateImageOutput({
    required Map<String, dynamic> output,
    required String id,
    String? fallbackPrompt,
  }) {
    final status = output['status'] as String?;
    final url = (output['url'] as String?)?.trim();
    final revisedPrompt = (output['revisedPrompt'] as String?)?.trim();
    final message = (output['message'] as String?)?.trim();
    final promptForNext = (revisedPrompt != null && revisedPrompt.isNotEmpty)
        ? revisedPrompt
        : fallbackPrompt?.trim();

    if (status == 'success' && url != null && url.isNotEmpty) {
      return ChatImagePart(
        id: id,
        status: ChatImagePartStatus.ready,
        url: url,
        revisedPrompt: promptForNext == null || promptForNext.isEmpty
            ? null
            : promptForNext,
      );
    }

    return ChatImagePart(
      id: id,
      status: ChatImagePartStatus.failed,
      errorMessage: message == null || message.isEmpty
          ? t.agent.generateImage.requestFailedResult
          : message,
    );
  }

  List<ChatMessagePart> _withoutPendingImageParts(List<ChatMessagePart> parts) {
    return [
      for (final part in parts)
        if (part is! ChatImagePart ||
            part.status != ChatImagePartStatus.generating)
          part,
    ];
  }

  Future<void> _throwIfAborted(Future<void>? abortTrigger) async {
    if (abortTrigger == null) {
      return;
    }
    if (await _isAbortCompleted(abortTrigger)) {
      throw const LlmAbortedException();
    }
  }

  Future<bool> _isAbortCompleted(Future<void> abortTrigger) {
    return abortTrigger
        .then((_) => true)
        .timeout(Duration.zero, onTimeout: () => false);
  }
}
