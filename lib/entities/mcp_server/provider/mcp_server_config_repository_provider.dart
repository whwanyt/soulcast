import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../mcp_server_config_entity.dart';
import '../repository/mcp_server_config_repository.dart';
import 'isar_provider.dart';

part 'mcp_server_config_repository_provider.g.dart';

/// 提供 MCP Server 配置仓库。
@Riverpod(keepAlive: true)
Future<McpServerConfigRepository> mcpServerConfigRepository(Ref ref) async {
  final isar = await ref.watch(mcpServerIsarProvider.future);
  return McpServerConfigRepository(isar);
}

/// 监听全部 MCP Server 配置。
@Riverpod(keepAlive: true)
Stream<List<McpServerConfigEntity>> mcpServers(Ref ref) async* {
  final repository = await ref.watch(mcpServerConfigRepositoryProvider.future);
  yield* repository.watchAll();
}
