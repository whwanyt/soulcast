part of 'chat_service.dart';

/// 聊天完成请求与远端响应轮询辅助。
mixin _ChatServiceHelpers on _ChatRequestBuilder {
  static const _remotePollInterval = Duration(seconds: 2);

  Future<LlmChatCompletion> _createChatCompletion({
    required LlmClient client,
    required ChatSettings settings,
    required List<LlmMessage> messages,
    required List<AgentTool> tools,
    required List<McpRemoteTool> mcpTools,
    LlmToolChoice? toolChoice,
    Future<void>? abortTrigger,
    void Function(String remoteResponseId)? onRemoteResponseId,
  }) {
    final definitions = _toolDefinitions(tools: tools, mcpTools: mcpTools);
    final resolvedChoice = _resolveToolChoice(
      hasTools: definitions.isNotEmpty,
      toolChoice: toolChoice,
    );
    return client.createChatCompletion(
      LlmChatRequest(
        model: settings.model,
        messages: messages,
        maxTokens: settings.maxTokens,
        maxCompletionTokens: settings.maxCompletionTokens,
        temperature: settings.temperature,
        topP: settings.topP,
        topK: settings.topK,
        tools: definitions.isEmpty ? null : definitions,
        toolChoice: resolvedChoice,
        parallelToolCalls: definitions.isEmpty ? null : true,
        onRemoteResponseId: onRemoteResponseId,
      ),
      abortTrigger: abortTrigger,
    );
  }

  Stream<LlmStreamSnapshot> _createChatCompletionStream({
    required LlmClient client,
    required ChatSettings settings,
    required List<LlmMessage> messages,
    required List<AgentTool> tools,
    required List<McpRemoteTool> mcpTools,
    LlmToolChoice? toolChoice,
    Future<void>? abortTrigger,
    void Function(String remoteResponseId)? onRemoteResponseId,
  }) {
    final definitions = _toolDefinitions(tools: tools, mcpTools: mcpTools);
    final resolvedChoice = _resolveToolChoice(
      hasTools: definitions.isNotEmpty,
      toolChoice: toolChoice,
    );
    return client.createChatCompletionStream(
      LlmChatRequest(
        model: settings.model,
        messages: messages,
        maxTokens: settings.maxTokens,
        maxCompletionTokens: settings.maxCompletionTokens,
        temperature: settings.temperature,
        topP: settings.topP,
        topK: settings.topK,
        includeUsageInStream: true,
        tools: definitions.isEmpty ? null : definitions,
        toolChoice: resolvedChoice,
        parallelToolCalls: definitions.isEmpty ? null : true,
        onRemoteResponseId: onRemoteResponseId,
      ),
      abortTrigger: abortTrigger,
    );
  }

  /// 轮询已落库的 background response，直到终态并映射为 completion。
  Future<LlmChatCompletion> _pollRemoteResponseUntilComplete({
    required LlmClient client,
    required String remoteResponseId,
    Future<void>? abortTrigger,
  }) async {
    while (true) {
      final poll = await client.pollRemoteResponse(
        remoteResponseId,
        abortTrigger: abortTrigger,
      );
      if (poll.isTerminal) {
        return _completionFromRemotePoll(poll);
      }
      await Future.any<void>([
        Future<void>.delayed(_remotePollInterval),
        ?abortTrigger,
      ]);
      if (abortTrigger != null) {
        final aborted = await Future.any<bool>([
          abortTrigger.then((_) => true),
          Future<bool>.value(false),
        ]);
        if (aborted) {
          throw const LlmAbortedException();
        }
      }
    }
  }

  LlmChatCompletion _completionFromRemotePoll(LlmRemotePollResult poll) {
    final completion = poll.completion;
    if (completion != null) {
      if (poll.state == LlmRemotePollState.failed) {
        throw LlmException(
          poll.errorMessage?.trim().isNotEmpty == true
              ? poll.errorMessage!
              : 'Remote response failed',
        );
      }
      if (poll.state == LlmRemotePollState.cancelled) {
        throw const LlmAbortedException('Remote response was cancelled');
      }
      return completion;
    }
    throw LlmException(
      poll.errorMessage?.trim().isNotEmpty == true
          ? poll.errorMessage!
          : 'Remote response ended without completion payload',
    );
  }

  LlmToolChoice? _resolveToolChoice({
    required bool hasTools,
    LlmToolChoice? toolChoice,
  }) {
    if (!hasTools) {
      return null;
    }
    return toolChoice ?? LlmToolChoice.auto;
  }
}
