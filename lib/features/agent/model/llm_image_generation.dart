/// Images generations 结果（领域层）。
///
/// 兼容 `url` 与 `b64_json`；部分模型（如 GPT Image）仅返回 base64。
class LlmImageGeneration {
  const LlmImageGeneration({this.url, this.b64Json, this.revisedPrompt});

  final String? url;
  final String? b64Json;
  final String? revisedPrompt;

  bool get hasUrl => url != null && url!.isNotEmpty;

  bool get hasB64Json => b64Json != null && b64Json!.isNotEmpty;
}
