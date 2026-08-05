import 'dart:convert';

import '../model/mcp_server_transfer_data.dart';

/// MCP Server JSON 的校验错误类型。
enum McpServerJsonError {
  invalidJson,
  invalidFields,
  missingRequiredField,
  unsupportedType,
}

/// 携带可本地化错误类型的 MCP Server JSON 异常。
class McpServerJsonException implements Exception {
  const McpServerJsonException(this.error);

  final McpServerJsonError error;
}

/// 严格编解码 `mcpServers` 格式的 Streamable HTTP 配置。
class McpServerJsonCodec {
  const McpServerJsonCodec();

  static const _rootKey = 'mcpServers';
  static const _allowedServerKeys = {'type', 'url', 'headers'};

  String encode(List<McpServerTransferData> servers) {
    final mcpServers = <String, Object>{
      for (final server in servers) server.name: server.toServerJson(),
    };
    return const JsonEncoder.withIndent('  ').convert({_rootKey: mcpServers});
  }

  List<McpServerTransferData> decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const McpServerJsonException(McpServerJsonError.invalidJson);
    }

    if (decoded is! Map<String, dynamic> || !decoded.containsKey(_rootKey)) {
      throw const McpServerJsonException(McpServerJsonError.invalidFields);
    }

    final rawServers = decoded[_rootKey];
    if (rawServers is! Map || rawServers.isEmpty) {
      throw const McpServerJsonException(McpServerJsonError.invalidFields);
    }

    final result = <McpServerTransferData>[];
    for (final entry in rawServers.entries) {
      final name = entry.key?.toString().trim() ?? '';
      final value = entry.value;
      if (name.isEmpty || value is! Map) {
        throw const McpServerJsonException(McpServerJsonError.invalidFields);
      }

      final serverMap = Map<String, dynamic>.from(value);
      if (serverMap.keys.any((key) => !_allowedServerKeys.contains(key))) {
        throw const McpServerJsonException(McpServerJsonError.invalidFields);
      }

      final type = serverMap['type'];
      if (type != null) {
        if (type is! String) {
          throw const McpServerJsonException(McpServerJsonError.invalidFields);
        }
        if (type.trim() != McpServerTransferData.typeStreamableHttp) {
          throw const McpServerJsonException(
            McpServerJsonError.unsupportedType,
          );
        }
      }

      final urlValue = serverMap['url'];
      if (urlValue is! String) {
        throw const McpServerJsonException(
          McpServerJsonError.missingRequiredField,
        );
      }
      final url = urlValue.trim();
      if (url.isEmpty) {
        throw const McpServerJsonException(
          McpServerJsonError.missingRequiredField,
        );
      }

      result.add(
        McpServerTransferData(
          name: name,
          url: url,
          bearerToken: _parseBearerToken(serverMap['headers']),
        ),
      );
    }

    return result;
  }

  static String _parseBearerToken(Object? headers) {
    if (headers == null) {
      return '';
    }
    if (headers is! Map) {
      throw const McpServerJsonException(McpServerJsonError.invalidFields);
    }

    final authorization = headers['Authorization'] ?? headers['authorization'];
    if (authorization == null) {
      return '';
    }
    if (authorization is! String) {
      throw const McpServerJsonException(McpServerJsonError.invalidFields);
    }

    final value = authorization.trim();
    const prefix = 'Bearer ';
    if (value.length > prefix.length &&
        value.substring(0, prefix.length).toLowerCase() == 'bearer ') {
      return value.substring(prefix.length).trim();
    }
    return value;
  }
}
