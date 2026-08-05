import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';

import '../model/mcp_connection_status.dart';
import '../model/mcp_remote_tool.dart';
import '../service/mcp_session_manager.dart';

part 'mcp_tools.g.dart';

/// 已连接 server 上发现的全部远程工具（含本地禁用项；设置页与聊天 MCP 面板共用）。
@Riverpod(keepAlive: true)
List<McpRemoteTool> mcpDiscoveredTools(Ref ref) {
  final sessions = ref.watch(mcpSessionManagerProvider);
  return [
    for (final session in sessions.values)
      if (session.status == McpConnectionStatus.connected) ...session.tools,
  ];
}

/// 暴露给模型的 MCP 工具（已连接且未在 server 配置中禁用）。
@Riverpod(keepAlive: true)
List<McpRemoteTool> mcpTools(Ref ref) {
  // 面板切换启用时 bump，保证过滤结果即时刷新。
  ref.watch(mcpServerActionsProvider);
  final sessions = ref.watch(mcpSessionManagerProvider);
  final serversAsync = ref.watch(mcpServersProvider);
  final servers = serversAsync.whenOrNull(data: (items) => items) ?? const [];
  final disabledByServer = {
    for (final server in servers)
      server.id: McpServerConfigRepository.decodeDisabledToolNames(
        server.disabledToolNamesJson,
      ).toSet(),
  };
  final discovered = ref.watch(mcpDiscoveredToolsProvider);
  return [
    for (final tool in discovered)
      if (sessions[tool.serverId]?.status == McpConnectionStatus.connected &&
          !(disabledByServer[tool.serverId]?.contains(tool.originalName) ??
              false))
        tool,
  ];
}

/// 返回指定 MCP Server 当前发现的全部工具。
@Riverpod(keepAlive: true)
List<McpRemoteTool> mcpDiscoveredToolsForServer(Ref ref, String serverId) {
  final session = ref.watch(mcpSessionManagerProvider)[serverId];
  if (session?.status != McpConnectionStatus.connected) {
    return const [];
  }
  return session!.tools;
}

/// 管理 MCP Server 配置及单工具启用状态，并同步连接会话。
@Riverpod(keepAlive: true)
class McpServerActions extends _$McpServerActions {
  @override
  int build() => 0;

  Future<McpServerConfigEntity> saveServer({
    String? serverId,
    required String name,
    required String url,
    bool? enabled,
    String? bearerToken,
    List<String>? disabledToolNames,
  }) async {
    final repository = await ref.read(mcpServerConfigRepositoryProvider.future);
    final entity = repository.upsert(
      serverId: serverId,
      name: name,
      url: url,
      enabled: enabled,
      bearerToken: bearerToken,
      disabledToolNames: disabledToolNames,
    );
    final manager = ref.read(mcpSessionManagerProvider.notifier);
    if (entity.enabled) {
      await manager.connectServer(entity);
    } else {
      await manager.disconnectServer(entity.id);
    }
    state++;
    return entity;
  }

  Future<bool> deleteServer(String serverId) async {
    final repository = await ref.read(mcpServerConfigRepositoryProvider.future);
    await ref
        .read(mcpSessionManagerProvider.notifier)
        .disconnectServer(serverId);
    final deleted = repository.delete(serverId);
    state++;
    return deleted;
  }

  Future<void> setEnabled(String serverId, {required bool enabled}) async {
    final repository = await ref.read(mcpServerConfigRepositoryProvider.future);
    final existing = repository.getById(serverId);
    if (existing == null) {
      return;
    }
    final entity = repository.upsert(
      serverId: existing.id,
      name: existing.name,
      url: existing.url,
      enabled: enabled,
      bearerToken: existing.bearerToken,
      disabledToolNames: McpServerConfigRepository.decodeDisabledToolNames(
        existing.disabledToolNamesJson,
      ),
    );
    final manager = ref.read(mcpSessionManagerProvider.notifier);
    if (entity.enabled) {
      await manager.connectServer(entity);
    } else {
      await manager.disconnectServer(entity.id);
    }
    state++;
  }

  /// 聊天面板切换单个远程工具启用状态（不重连 Server）。
  Future<void> setToolEnabled({
    required String serverId,
    required String originalName,
    required bool enabled,
  }) async {
    final repository = await ref.read(mcpServerConfigRepositoryProvider.future);
    final existing = repository.getById(serverId);
    if (existing == null) {
      return;
    }
    final disabled = McpServerConfigRepository.decodeDisabledToolNames(
      existing.disabledToolNamesJson,
    ).toSet();
    if (enabled) {
      disabled.remove(originalName);
    } else {
      disabled.add(originalName);
    }
    repository.upsert(
      serverId: existing.id,
      name: existing.name,
      url: existing.url,
      enabled: existing.enabled,
      bearerToken: existing.bearerToken,
      disabledToolNames: disabled.toList(growable: false),
    );
    state++;
  }

  Future<int> testConnection({required String url, String? bearerToken}) async {
    final draft = McpServerConfigEntity(
      id: 'test',
      name: 'test',
      url: url,
      enabled: true,
      bearerToken: bearerToken ?? '',
      disabledToolNamesJson: '[]',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return ref.read(mcpSessionManagerProvider.notifier).testConnection(draft);
  }
}
