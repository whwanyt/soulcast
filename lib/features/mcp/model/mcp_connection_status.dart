import 'mcp_remote_tool.dart';

/// MCP Server 会话连接状态。
enum McpConnectionStatus { disconnected, connecting, connected, error }

/// 单个 MCP Server 的连接结果与远端工具快照。
class McpServerSessionState {
  const McpServerSessionState({
    required this.serverId,
    required this.status,
    this.errorMessage,
    this.tools = const [],
  });

  final String serverId;
  final McpConnectionStatus status;
  final String? errorMessage;

  /// 已发现的远程工具；仅 [McpConnectionStatus.connected] 时非空。
  final List<McpRemoteTool> tools;

  int get discoveredToolCount => tools.length;

  McpServerSessionState copyWith({
    McpConnectionStatus? status,
    String? errorMessage,
    List<McpRemoteTool>? tools,
    bool clearError = false,
  }) {
    return McpServerSessionState(
      serverId: serverId,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      tools: tools ?? this.tools,
    );
  }
}
