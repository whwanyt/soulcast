const mcpQualifiedNamePrefix = 'mcp__';

/// 为远端工具添加 Server 命名空间，避免跨 Server 重名。
String qualifyMcpToolName({
  required String serverId,
  required String originalName,
}) {
  return '$mcpQualifiedNamePrefix${serverId}__$originalName';
}

/// 判断名称是否使用 MCP 限定格式。
bool isMcpQualifiedToolName(String name) {
  return name.startsWith(mcpQualifiedNamePrefix);
}

/// 解析限定名称中的 Server id 与原始工具名；格式无效时返回 `null`。
({String serverId, String originalName})? parseMcpQualifiedToolName(
  String name,
) {
  if (!isMcpQualifiedToolName(name)) {
    return null;
  }
  final rest = name.substring(mcpQualifiedNamePrefix.length);
  final separatorIndex = rest.indexOf('__');
  if (separatorIndex <= 0 || separatorIndex >= rest.length - 2) {
    return null;
  }
  return (
    serverId: rest.substring(0, separatorIndex),
    originalName: rest.substring(separatorIndex + 2),
  );
}
