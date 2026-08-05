import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/mcp_server_transfer_service.dart';

part 'mcp_server_transfer_service.g.dart';

/// 提供 MCP Server JSON 导入导出服务。
@Riverpod(keepAlive: true)
McpServerTransferService mcpServerTransferService(Ref ref) {
  return const McpServerTransferService();
}
