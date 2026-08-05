/// Images generations 请求（领域层）。
class LlmImageRequest {
  const LlmImageRequest({
    required this.prompt,
    required this.model,
    this.size,
    this.n = 1,
  });

  final String prompt;
  final String model;

  /// 如 `1024x1024`；`null` 表示由服务端默认。
  final String? size;

  final int n;
}
