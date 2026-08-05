/// 已从 MCP Server 发现并映射到应用命名空间的远端工具。
class McpRemoteTool {
  const McpRemoteTool({
    required this.qualifiedName,
    required this.serverId,
    required this.serverName,
    required this.originalName,
    required this.displayName,
    required this.description,
    this.parameters,
  });

  final String qualifiedName;
  final String serverId;
  final String serverName;
  final String originalName;
  final String displayName;
  final String description;
  final Map<String, dynamic>? parameters;
}
