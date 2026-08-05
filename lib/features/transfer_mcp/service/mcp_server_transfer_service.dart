import 'package:flutter/services.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';

import '../model/mcp_server_transfer_data.dart';
import 'mcp_server_json_codec.dart';

/// MCP Server JSON 的剪贴板写入 Port。
typedef McpServerClipboardWriter = Future<void> Function(String text);

/// 编排单个或全部 MCP Server 的剪贴板导出与 JSON 导入。
class McpServerTransferService {
  const McpServerTransferService({
    this.codec = const McpServerJsonCodec(),
    this.clipboardWriter = _writeClipboard,
  });

  final McpServerJsonCodec codec;
  final McpServerClipboardWriter clipboardWriter;

  Future<String> exportToClipboard(McpServerConfigEntity server) async {
    final json = codec.encode([McpServerTransferData.fromServer(server)]);
    await clipboardWriter(json);
    return json;
  }

  Future<String> exportAllToClipboard(
    List<McpServerConfigEntity> servers,
  ) async {
    final json = codec.encode([
      for (final server in servers) McpServerTransferData.fromServer(server),
    ]);
    await clipboardWriter(json);
    return json;
  }

  List<McpServerConfigEntity> importFromJson({
    required String json,
    required McpServerConfigRepository repository,
  }) {
    final items = codec.decode(json);
    return [
      for (final item in items)
        repository.upsert(
          name: item.name,
          url: item.url,
          bearerToken: item.bearerToken,
          enabled: true,
        ),
    ];
  }
}

Future<void> _writeClipboard(String text) {
  return Clipboard.setData(ClipboardData(text: text));
}
