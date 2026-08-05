import 'package:mcp_dart/mcp_dart.dart';

/// 创建带应用标识的 MCP 客户端。
McpClient createMcpClient() {
  return McpClient(const Implementation(name: 'soulcast', version: '1.0.0'));
}

/// 创建支持可选 Bearer Token 的 Streamable HTTP 传输层。
StreamableHttpClientTransport createMcpHttpTransport({
  required Uri url,
  String? bearerToken,
}) {
  final token = bearerToken?.trim();
  final headers = <String, dynamic>{
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
  return StreamableHttpClientTransport(
    url,
    opts: StreamableHttpClientTransportOptions(
      requestInit: headers.isEmpty ? null : {'headers': headers},
    ),
  );
}
