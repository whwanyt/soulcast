import 'package:flute_core/log/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';

import '../api/mcp_call_result_mapper.dart';
import '../api/mcp_connected_client.dart';
import '../model/mcp_connection_status.dart';
import '../model/mcp_remote_tool.dart';
import 'mcp_tool_name.dart';
import 'mcp_tool_runner.dart';

part 'mcp_session_manager.g.dart';

/// 管理 MCP Server 客户端连接、工具发现与远程调用生命周期。
@Riverpod(keepAlive: true)
class McpSessionManager extends _$McpSessionManager implements McpToolRunner {
  final Map<String, McpConnectedClient> _clients = {};

  @override
  Map<String, McpServerSessionState> build() {
    ref.onDispose(_closeAll);
    return const {};
  }

  /// 已连接 server 上发现的全部远程工具（含本地禁用项）。
  List<McpRemoteTool> get discoveredTools {
    return [
      for (final session in state.values)
        if (session.status == McpConnectionStatus.connected) ...session.tools,
    ];
  }

  List<McpRemoteTool> discoveredToolsFor(String serverId) {
    final session = state[serverId];
    if (session?.status != McpConnectionStatus.connected) {
      return const [];
    }
    return session!.tools;
  }

  Future<void> syncEnabledServers() async {
    final servers = await _loadServers();
    final enabledIds = {
      for (final server in servers)
        if (server.enabled) server.id,
    };

    for (final serverId in {..._clients.keys}) {
      if (!enabledIds.contains(serverId)) {
        await disconnectServer(serverId);
      }
    }

    await Future.wait([
      for (final server in servers)
        if (server.enabled) connectServer(server),
    ]);
  }

  Future<void> connectServer(McpServerConfigEntity server) async {
    final serverId = server.id;
    _setSession(
      McpServerSessionState(
        serverId: serverId,
        status: McpConnectionStatus.connecting,
      ),
    );

    try {
      await disconnectServer(serverId, notify: false);

      final client = await connectMcpHttpClient(
        url: Uri.parse(server.url),
        bearerToken: server.bearerToken,
      );
      final listed = await client.listTools();
      final tools = [
        for (final tool in listed) _toRemoteTool(server: server, tool: tool),
      ];

      _clients[serverId] = client;
      _setSession(
        McpServerSessionState(
          serverId: serverId,
          status: McpConnectionStatus.connected,
          tools: tools,
        ),
      );
      Log.d(
        'MCP server connected: id=$serverId, tools=${tools.length}',
        tag: 'Mcp',
      );
    } catch (error, stackTrace) {
      await disconnectServer(serverId, notify: false);
      _setSession(
        McpServerSessionState(
          serverId: serverId,
          status: McpConnectionStatus.error,
          errorMessage: error.toString(),
        ),
      );
      Log.e(
        'MCP server connect failed: id=$serverId, error=$error',
        tag: 'Mcp',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<int> testConnection(McpServerConfigEntity server) async {
    final client = await connectMcpHttpClient(
      url: Uri.parse(server.url),
      bearerToken: server.bearerToken,
    );
    try {
      final listed = await client.listTools();
      return listed.length;
    } finally {
      await client.close();
    }
  }

  Future<void> disconnectServer(String serverId, {bool notify = true}) async {
    final client = _clients.remove(serverId);
    if (client != null) {
      try {
        await client.close();
      } catch (error, stackTrace) {
        Log.e(
          'MCP server close failed: id=$serverId, error=$error',
          tag: 'Mcp',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (notify) {
      _setSession(
        McpServerSessionState(
          serverId: serverId,
          status: McpConnectionStatus.disconnected,
        ),
      );
    }
  }

  Future<void> refreshServerTools(McpServerConfigEntity server) async {
    if (!server.enabled) {
      await disconnectServer(server.id);
      return;
    }
    await connectServer(server);
  }

  @override
  Future<Map<String, dynamic>> callTool(
    String qualifiedName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final parsed = parseMcpQualifiedToolName(qualifiedName);
      if (parsed == null) {
        throw McpToolCallException('Invalid MCP tool name: $qualifiedName');
      }

      final client = _clients[parsed.serverId];
      if (client == null) {
        throw McpToolCallException(
          'MCP server is not connected: ${parsed.serverId}',
        );
      }

      return client.callTool(name: parsed.originalName, arguments: arguments);
    } catch (error, stackTrace) {
      Log.e(
        'MCP callTool failed: name=$qualifiedName, error=$error',
        tag: 'MCP',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<McpServerConfigEntity>> _loadServers() async {
    final repository = await ref.read(mcpServerConfigRepositoryProvider.future);
    return repository.getAll();
  }

  void _setSession(McpServerSessionState session) {
    state = {...state, session.serverId: session};
  }

  McpRemoteTool _toRemoteTool({
    required McpServerConfigEntity server,
    required McpListedToolInfo tool,
  }) {
    final originalName = tool.name;
    return McpRemoteTool(
      qualifiedName: qualifyMcpToolName(
        serverId: server.id,
        originalName: originalName,
      ),
      serverId: server.id,
      serverName: server.name,
      originalName: originalName,
      displayName: '${server.name}: ${tool.title ?? originalName}',
      description: tool.description?.trim().isNotEmpty == true
          ? tool.description!.trim()
          : 'MCP tool $originalName from ${server.name}',
      parameters: tool.inputSchema,
    );
  }

  Future<void> _closeAll() async {
    final ids = _clients.keys.toList(growable: false);
    for (final id in ids) {
      await disconnectServer(id, notify: false);
    }
  }
}
