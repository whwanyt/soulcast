import 'package:soulcast/entities/mcp_server/mcp_server.dart';

/// MCP Server 导入导出使用的 Streamable HTTP 配置。
class McpServerTransferData {
  const McpServerTransferData({
    required this.name,
    required this.url,
    this.bearerToken = '',
  });

  factory McpServerTransferData.fromServer(McpServerConfigEntity server) {
    return McpServerTransferData(
      name: server.name,
      url: server.url,
      bearerToken: server.bearerToken,
    );
  }

  final String name;
  final String url;
  final String bearerToken;

  static const typeStreamableHttp = 'streamable_http';

  Map<String, Object> toServerJson() {
    final token = bearerToken.trim();
    return {
      'type': typeStreamableHttp,
      'url': url,
      if (token.isNotEmpty) 'headers': {'Authorization': 'Bearer $token'},
    };
  }
}
