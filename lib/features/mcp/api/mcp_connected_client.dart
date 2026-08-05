import 'package:mcp_dart/mcp_dart.dart';

import 'mcp_call_result_mapper.dart';
import 'mcp_client_factory.dart';

/// 已连接 MCP server 上发现的工具（项目侧 DTO，不含 mcp_dart 类型）。
class McpListedToolInfo {
  const McpListedToolInfo({
    required this.name,
    required this.inputSchema,
    this.title,
    this.description,
  });

  final String name;
  final String? title;
  final String? description;
  final Map<String, dynamic> inputSchema;
}

/// 对 mcp_dart [McpClient] 的薄封装，供 service 编排使用。
abstract interface class McpConnectedClient {
  Future<List<McpListedToolInfo>> listTools();

  Future<Map<String, dynamic>> callTool({
    required String name,
    required Map<String, dynamic> arguments,
  });

  Future<void> close();
}

/// 建立 MCP Streamable HTTP 连接并返回项目侧客户端封装。
Future<McpConnectedClient> connectMcpHttpClient({
  required Uri url,
  String? bearerToken,
}) async {
  final client = createMcpClient();
  final transport = createMcpHttpTransport(url: url, bearerToken: bearerToken);
  await client.connect(transport);
  return _McpDartConnectedClient(client);
}

final class _McpDartConnectedClient implements McpConnectedClient {
  _McpDartConnectedClient(this._client);

  final McpClient _client;

  @override
  Future<List<McpListedToolInfo>> listTools() async {
    final listed = await _client.listTools();
    return [
      for (final tool in listed.tools)
        McpListedToolInfo(
          name: tool.name,
          title: tool.title,
          description: tool.description,
          inputSchema: tool.inputSchema.toJson(),
        ),
    ];
  }

  @override
  Future<Map<String, dynamic>> callTool({
    required String name,
    required Map<String, dynamic> arguments,
  }) async {
    final result = await _client.callTool(
      CallToolRequest(name: name, arguments: arguments),
    );
    return mapMcpCallToolResult(result);
  }

  @override
  Future<void> close() => _client.close();
}
