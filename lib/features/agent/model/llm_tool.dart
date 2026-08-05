import 'dart:convert';

/// Function tool 定义（Chat Completions tools[]）。
class LlmToolDefinition {
  const LlmToolDefinition({
    required this.name,
    required this.description,
    this.parameters,
    this.strict = false,
  });

  final String name;
  final String description;
  final Map<String, dynamic>? parameters;
  final bool strict;
}

/// 模型发起的 function tool call。
class LlmToolCall {
  const LlmToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;

  /// JSON 字符串形式的参数。
  final String arguments;

  Map<String, dynamic> get argumentsMap {
    final decoded = jsonDecode(arguments);
    if (decoded is! Map) {
      throw const FormatException(
        'LlmToolCall.arguments must be a JSON object',
      );
    }
    return decoded.cast<String, dynamic>();
  }
}
