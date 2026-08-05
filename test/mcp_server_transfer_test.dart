import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';
import 'package:soulcast/features/transfer_mcp/model/mcp_server_transfer_data.dart';
import 'package:soulcast/features/transfer_mcp/service/mcp_server_json_codec.dart';
import 'package:soulcast/features/transfer_mcp/service/mcp_server_transfer_service.dart';

void main() {
  test('MCP JSON wraps servers as mcpServers streamable_http', () async {
    final server = McpServerConfigEntity(
      id: 'mcp_export',
      name: 'bing-cn-mcp-server',
      url: 'https://example.com/mcp',
      enabled: true,
      bearerToken: '',
      disabledToolNamesJson: '[]',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    String? clipboardText;
    final service = McpServerTransferService(
      clipboardWriter: (text) async => clipboardText = text,
    );

    final exported = await service.exportToClipboard(server);
    final json = jsonDecode(exported) as Map<String, dynamic>;
    final mcpServers = json['mcpServers'] as Map<String, dynamic>;
    final entry = mcpServers['bing-cn-mcp-server'] as Map<String, dynamic>;

    expect(clipboardText, exported);
    expect(json.keys, ['mcpServers']);
    expect(entry, {
      'type': 'streamable_http',
      'url': 'https://example.com/mcp',
    });
    expect(exported, isNot(contains('mcp_export')));
    expect(exported, isNot(contains('disabledToolNames')));
  });

  test('MCP JSON includes Authorization header when bearer token exists', () {
    const codec = McpServerJsonCodec();
    final encoded = codec.encode([
      const McpServerTransferData(
        name: 'secured',
        url: 'https://example.com/mcp',
        bearerToken: 'secret-token',
      ),
    ]);
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    final entry =
        (json['mcpServers'] as Map<String, dynamic>)['secured']
            as Map<String, dynamic>;

    expect(entry['headers'], {'Authorization': 'Bearer secret-token'});
  });

  test('MCP JSON decoder accepts ModelScope-style streamable_http config', () {
    const codec = McpServerJsonCodec();
    final decoded = codec.decode('''
{
  "mcpServers": {
    "bing-cn-mcp-server": {
      "type": "streamable_http",
      "url": "https://example.com/mcp"
    }
  }
}
''');

    expect(decoded, hasLength(1));
    expect(decoded.single.name, 'bing-cn-mcp-server');
    expect(
      decoded.single.url,
      'https://example.com/mcp',
    );
    expect(decoded.single.bearerToken, isEmpty);
  });

  test('MCP JSON decoder rejects unsupported transport types', () {
    const codec = McpServerJsonCodec();

    expect(
      () => codec.decode('''
{
  "mcpServers": {
    "local": {
      "type": "stdio",
      "url": "https://example.com/mcp"
    }
  }
}
'''),
      throwsA(
        isA<McpServerJsonException>().having(
          (error) => error.error,
          'error',
          McpServerJsonError.unsupportedType,
        ),
      ),
    );
  });

  test('MCP JSON decoder rejects unknown server fields', () {
    const codec = McpServerJsonCodec();

    expect(
      () => codec.decode('''
{
  "mcpServers": {
    "local": {
      "type": "streamable_http",
      "url": "https://example.com/mcp",
      "command": "npx"
    }
  }
}
'''),
      throwsA(
        isA<McpServerJsonException>().having(
          (error) => error.error,
          'error',
          McpServerJsonError.invalidFields,
        ),
      ),
    );
  });
}
