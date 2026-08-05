/// ChatService 调用 MCP 的抽象，避免依赖 session 具体实现细节。
abstract class McpToolRunner {
  Future<Map<String, dynamic>> callTool(
    String qualifiedName,
    Map<String, dynamic> arguments,
  );
}
