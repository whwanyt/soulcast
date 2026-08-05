import 'llm_chat_completion.dart';

/// 远程 background response 的状态。
enum LlmRemotePollState { inProgress, completed, failed, cancelled, incomplete }

/// `retrieve` 一次查询的领域结果。
class LlmRemotePollResult {
  const LlmRemotePollResult({
    required this.state,
    this.completion,
    this.errorMessage,
  });

  final LlmRemotePollState state;
  final LlmChatCompletion? completion;
  final String? errorMessage;

  bool get isTerminal =>
      state == LlmRemotePollState.completed ||
      state == LlmRemotePollState.failed ||
      state == LlmRemotePollState.cancelled ||
      state == LlmRemotePollState.incomplete;
}
