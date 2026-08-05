import '../model/llm_chat_completion.dart';
import '../model/llm_chat_request.dart';
import '../model/llm_image_generation.dart';
import '../model/llm_image_request.dart';
import '../model/llm_remote_poll_result.dart';
import '../model/llm_stream_snapshot.dart';
import '../model/remote_ai_model.dart';

/// LLM 传输层 Port。编排层只依赖本接口与领域 DTO。
abstract class LlmClient {
  Future<LlmChatCompletion> createChatCompletion(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  });

  Stream<LlmStreamSnapshot> createChatCompletionStream(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  });

  /// 轮询 Responses background 任务；不支持时抛 [LlmException]。
  Future<LlmRemotePollResult> pollRemoteResponse(
    String remoteResponseId, {
    Future<void>? abortTrigger,
  });

  /// 取消 Responses background 任务；不支持时抛 [LlmException]。
  Future<void> cancelRemoteResponse(
    String remoteResponseId, {
    Future<void>? abortTrigger,
  });

  Future<LlmImageGeneration> createImage(LlmImageRequest request);

  Future<List<RemoteAiModel>> listModels();

  void close();
}

/// 领域层 LLM 异常（不暴露 SDK 异常类型）。
class LlmException implements Exception {
  const LlmException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'LlmException: $message';
}

/// 请求被中止。
class LlmAbortedException extends LlmException {
  const LlmAbortedException([
    super.message = 'Request was aborted',
    Object? cause,
  ]) : super(cause: cause);
}
