import 'package:flute_core/log/log.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';

import '../model/chat_settings.dart';
import '../model/llm_chat_completion.dart';
import '../model/llm_chat_request.dart';
import '../model/llm_image_generation.dart';
import '../model/llm_image_request.dart';
import '../model/llm_remote_poll_result.dart';
import '../model/llm_stream_snapshot.dart';
import '../model/remote_ai_model.dart';
import 'llm_client.dart';
import 'openai_llm_mapper.dart';
import 'openai_responses_mapper.dart';

/// OpenAI 兼容协议的 [LlmClient] 实现。
///
/// `openai_dart` 仅允许出现在 `features/agent/api/`（本文件与 mapper）。
class OpenAiCompatibleLlmClient implements LlmClient {
  OpenAiCompatibleLlmClient(
    this._client, {
    this.apiMode = AiProviderApiMode.chatCompletions,
    this.backgroundEnabled = false,
  });

  factory OpenAiCompatibleLlmClient.fromSettings(ChatSettings settings) {
    Log.d(
      'LLM client creating: baseUrl=${settings.apiBaseUrl}, '
      'apiMode=${settings.apiMode.name}, '
      'background=${settings.usesBackgroundResponse}, '
      'timeout=${settings.timeout.inSeconds}s, '
      'connectTimeout=${settings.connectTimeout.inSeconds}s, '
      'maxRetries=${settings.maxRetries}',
      tag: 'Chat',
    );
    return OpenAiCompatibleLlmClient(
      OpenAIClient(
        config: OpenAIConfig(
          authProvider: ApiKeyProvider(settings.apiKey),
          baseUrl: settings.apiBaseUrl,
          timeout: settings.timeout,
          connectTimeout: settings.connectTimeout,
          retryPolicy: RetryPolicy(maxRetries: settings.maxRetries),
          organization: settings.organization,
          project: settings.project,
        ),
      ),
      apiMode: settings.apiMode,
      backgroundEnabled: settings.usesBackgroundResponse,
    );
  }

  factory OpenAiCompatibleLlmClient.withApiKey({
    required String apiKey,
    required String baseUrl,
    AiProviderApiMode apiMode = AiProviderApiMode.chatCompletions,
    bool backgroundEnabled = false,
  }) {
    return OpenAiCompatibleLlmClient(
      OpenAIClient.withApiKey(
        apiKey,
        baseUrl: baseUrl,
        defaultHeaders: const {'Accept': 'application/json'},
      ),
      apiMode: apiMode,
      backgroundEnabled: backgroundEnabled,
    );
  }

  final OpenAIClient _client;
  final AiProviderApiMode apiMode;
  final bool backgroundEnabled;

  bool get _usesBackground =>
      apiMode == AiProviderApiMode.responses && backgroundEnabled;

  static const _pollInterval = Duration(seconds: 2);

  @override
  Future<LlmChatCompletion> createChatCompletion(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  }) async {
    if (apiMode == AiProviderApiMode.responses) {
      return _createResponsesCompletion(request, abortTrigger: abortTrigger);
    }
    try {
      final response = await _client.chat.completions.create(
        toOpenAiChatCompletionRequest(request),
        abortTrigger: abortTrigger,
      );
      return toLlmChatCompletion(response);
    } on AbortedException catch (error) {
      throw LlmAbortedException(error.message, error);
    } on OpenAIException catch (error, stackTrace) {
      Log.e(
        'LLM chat completion failed: ${error.message}',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      throw LlmException(error.message, cause: error);
    }
  }

  @override
  Stream<LlmStreamSnapshot> createChatCompletionStream(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  }) async* {
    if (apiMode == AiProviderApiMode.responses) {
      yield* _createResponsesCompletionStream(
        request,
        abortTrigger: abortTrigger,
      );
      return;
    }
    final accumulator = ChatStreamAccumulator();
    try {
      await for (final event in _client.chat.completions.createStream(
        toOpenAiChatCompletionRequest(request),
        abortTrigger: abortTrigger,
      )) {
        accumulator.add(event);
        yield toLlmStreamSnapshot(accumulator);
      }
    } on AbortedException catch (error) {
      throw LlmAbortedException(error.message, error);
    } on OpenAIException catch (error, stackTrace) {
      Log.e(
        'LLM chat completion stream failed: ${error.message}',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      throw LlmException(error.message, cause: error);
    }
  }

  Future<LlmChatCompletion> _createResponsesCompletion(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  }) async {
    try {
      final created = await _client.responses.create(
        toOpenAiCreateResponseRequest(
          request,
          stream: false,
          background: _usesBackground,
        ),
        abortTrigger: abortTrigger,
      );
      if (_usesBackground) {
        _notifyRemoteResponseId(request, created.id);
      }

      if (created.isComplete ||
          created.isFailed ||
          created.status == ResponseStatus.cancelled ||
          created.status == ResponseStatus.incomplete) {
        final poll = toLlmRemotePollResult(created);
        return _completionFromPoll(poll);
      }

      if (!_usesBackground) {
        throw LlmException(
          'Responses request is still ${created.status.toJson()} '
          'without background mode',
        );
      }

      return _pollUntilComplete(created.id, abortTrigger: abortTrigger);
    } on LlmException {
      rethrow;
    } on AbortedException catch (error) {
      throw LlmAbortedException(error.message, error);
    } on OpenAIException catch (error, stackTrace) {
      Log.e(
        'LLM responses completion failed: ${error.message}',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      throw LlmException(error.message, cause: error);
    }
  }

  Stream<LlmStreamSnapshot> _createResponsesCompletionStream(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  }) async* {
    final accumulator = ResponsesStreamSnapshotAccumulator();
    var notifiedId = false;
    try {
      await for (final event in _client.responses.createStream(
        toOpenAiCreateResponseRequest(
          request,
          stream: true,
          background: _usesBackground,
        ),
        abortTrigger: abortTrigger,
      )) {
        accumulator.add(event);
        final id = accumulator.responseId;
        if (_usesBackground && !notifiedId && id != null && id.isNotEmpty) {
          notifiedId = true;
          _notifyRemoteResponseId(request, id);
        }
        yield accumulator.toSnapshot();
      }

      // 仅 background 任务可在流断开后继续 retrieve。
      if (_usesBackground && !accumulator.isTerminal) {
        final id = accumulator.responseId;
        if (id == null || id.isEmpty) {
          return;
        }
        final completion = await _pollUntilComplete(
          id,
          abortTrigger: abortTrigger,
        );
        yield LlmStreamSnapshot(
          id: completion.id,
          content: completion.text ?? '',
          refusal: completion.refusal ?? '',
          finishReason: completion.finishReason,
          usage: completion.usage,
          toolCalls: completion.toolCalls,
          reasoningContent: completion.message?.reasoningContent ?? '',
          reasoning: completion.message?.reasoning ?? '',
          reasoningDetailTexts:
              completion.message?.reasoningDetails ?? const [],
        );
      }
    } on LlmException {
      rethrow;
    } on AbortedException catch (error) {
      throw LlmAbortedException(error.message, error);
    } on OpenAIException catch (error, stackTrace) {
      Log.e(
        'LLM responses stream failed: ${error.message}',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      throw LlmException(error.message, cause: error);
    }
  }

  Future<LlmChatCompletion> _pollUntilComplete(
    String remoteResponseId, {
    Future<void>? abortTrigger,
  }) async {
    while (true) {
      await _ensureNotAborted(abortTrigger);
      final poll = await pollRemoteResponse(
        remoteResponseId,
        abortTrigger: abortTrigger,
      );
      if (poll.isTerminal) {
        return _completionFromPoll(poll);
      }
      await Future.any<void>([
        Future<void>.delayed(_pollInterval),
        ?abortTrigger,
      ]);
      await _ensureNotAborted(abortTrigger);
    }
  }

  LlmChatCompletion _completionFromPoll(LlmRemotePollResult poll) {
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

  @override
  Future<LlmRemotePollResult> pollRemoteResponse(
    String remoteResponseId, {
    Future<void>? abortTrigger,
  }) async {
    if (apiMode != AiProviderApiMode.responses) {
      throw const LlmException(
        'pollRemoteResponse is only supported in Responses API mode',
      );
    }
    try {
      final response = await _client.responses.retrieve(
        remoteResponseId,
        abortTrigger: abortTrigger,
      );
      return toLlmRemotePollResult(response);
    } on AbortedException catch (error) {
      throw LlmAbortedException(error.message, error);
    } on OpenAIException catch (error, stackTrace) {
      Log.e(
        'LLM responses retrieve failed: ${error.message}',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      throw LlmException(error.message, cause: error);
    }
  }

  @override
  Future<void> cancelRemoteResponse(
    String remoteResponseId, {
    Future<void>? abortTrigger,
  }) async {
    if (apiMode != AiProviderApiMode.responses) {
      throw const LlmException(
        'cancelRemoteResponse is only supported in Responses API mode',
      );
    }
    try {
      await _client.responses.cancel(
        remoteResponseId,
        abortTrigger: abortTrigger,
      );
    } on AbortedException catch (error) {
      throw LlmAbortedException(error.message, error);
    } on OpenAIException catch (error, stackTrace) {
      Log.e(
        'LLM responses cancel failed: ${error.message}',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      throw LlmException(error.message, cause: error);
    }
  }

  @override
  Future<LlmImageGeneration> createImage(LlmImageRequest request) async {
    try {
      final response = await _client.images.generate(
        toOpenAiImageGenerationRequest(request),
      );
      final generation = toLlmImageGeneration(response);
      if (generation == null) {
        const exception = LlmException(
          'Image generation returned neither url nor b64_json',
        );
        Log.e(
          'LLM image generation failed: ${exception.message}',
          tag: 'Chat',
          error: exception,
        );
        throw exception;
      }
      return generation;
    } on LlmException {
      rethrow;
    } on AbortedException catch (error) {
      throw LlmAbortedException(error.message, error);
    } on OpenAIException catch (error, stackTrace) {
      Log.e(
        'LLM image generation failed: ${error.message}',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      throw LlmException(error.message, cause: error);
    }
  }

  @override
  Future<List<RemoteAiModel>> listModels() async {
    try {
      final models = await _client.models.list();
      return models.data
          .map(
            (model) => RemoteAiModel(
              id: model.id.trim(),
              object: model.object,
              ownedBy: model.ownedBy,
            ),
          )
          .where((model) => model.id.isNotEmpty)
          .toList()
        ..sort((first, second) => first.id.compareTo(second.id));
    } on AbortedException catch (error) {
      throw LlmAbortedException(error.message, error);
    } on OpenAIException catch (error, stackTrace) {
      Log.e(
        'LLM list models failed: ${error.message}',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      throw LlmException(error.message, cause: error);
    }
  }

  @override
  void close() {
    _client.close();
  }

  void _notifyRemoteResponseId(LlmChatRequest request, String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return;
    }
    request.onRemoteResponseId?.call(trimmed);
  }

  Future<void> _ensureNotAborted(Future<void>? abortTrigger) async {
    if (abortTrigger == null) {
      return;
    }
    final aborted = await Future.any<bool>([
      abortTrigger.then((_) => true),
      Future<bool>.value(false),
    ]);
    if (aborted) {
      throw const LlmAbortedException();
    }
  }
}
