part of 'chat_service.dart';

/// 一次工具执行对应的 API 回传消息与 UI 展示片段。
class _ToolCallResult {
  const _ToolCallResult({required this.apiMessage, required this.part});

  final LlmMessage apiMessage;
  final ChatToolCallPart part;
}
