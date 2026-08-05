import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';

/// 将 mcp_dart [CallToolResult] 规范化为可 JSON 编码的 Map。
///
/// [CallToolResult.isError] 为 true 时抛出 [McpToolCallException]。
Map<String, dynamic> mapMcpCallToolResult(CallToolResult result) {
  return mapMcpCallToolResultData(
    isError: result.isError,
    content: [for (final item in result.content) _contentToJson(item)],
    structuredContent: result.structuredContent,
  );
}

/// 纯数据版映射，便于单测且不依赖 Content 子类。
Map<String, dynamic> mapMcpCallToolResultData({
  required bool isError,
  required List<Map<String, dynamic>> content,
  Map<String, dynamic>? structuredContent,
}) {
  final texts = <String>[];
  final others = <Map<String, dynamic>>[];

  for (final item in content) {
    final type = item['type']?.toString();
    if (type == 'text' && item['text'] is String) {
      texts.add(item['text'] as String);
    } else {
      others.add(item);
    }
  }

  final payload = <String, dynamic>{
    'structuredContent': ?structuredContent,
    if (texts.isNotEmpty) 'text': texts.length == 1 ? texts.first : texts,
    if (others.isNotEmpty) 'content': others,
  };

  if (payload.isEmpty) {
    payload['text'] = '';
  }

  if (isError) {
    throw McpToolCallException(
      payload['text']?.toString() ?? 'MCP tool returned an error',
      payload: payload,
    );
  }

  return payload;
}

/// 将已规范化的 MCP 工具结果编码为模型可读 JSON。
String encodeMcpCallToolResult(Map<String, dynamic> payload) {
  return jsonEncode(payload);
}

Map<String, dynamic> _contentToJson(Content content) {
  return switch (content) {
    TextContent(:final text) => {'type': 'text', 'text': text},
    ImageContent(:final mimeType) => {'type': 'image', 'mimeType': mimeType},
    AudioContent(:final mimeType) => {'type': 'audio', 'mimeType': mimeType},
    ResourceLink(:final uri) => {'type': 'resource_link', 'uri': uri},
    EmbeddedResource() => {'type': 'resource'},
    _ => {'type': content.type},
  };
}

/// MCP 工具返回错误或调用失败时的领域异常。
class McpToolCallException implements Exception {
  const McpToolCallException(this.message, {this.payload});

  final String message;
  final Map<String, dynamic>? payload;

  @override
  String toString() => message;
}
