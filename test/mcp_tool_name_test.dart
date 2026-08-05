import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/features/mcp/mcp.dart';

void main() {
  group('mcp tool name', () {
    test('qualify and parse round-trip', () {
      final qualified = qualifyMcpToolName(
        serverId: 'mcp_123',
        originalName: 'search_docs',
      );
      expect(qualified, 'mcp__mcp_123__search_docs');
      expect(isMcpQualifiedToolName(qualified), isTrue);

      final parsed = parseMcpQualifiedToolName(qualified);
      expect(parsed?.serverId, 'mcp_123');
      expect(parsed?.originalName, 'search_docs');
    });

    test('supports original names containing underscores', () {
      final qualified = qualifyMcpToolName(
        serverId: 'mcp_1',
        originalName: 'foo_bar_baz',
      );
      final parsed = parseMcpQualifiedToolName(qualified);
      expect(parsed?.originalName, 'foo_bar_baz');
    });

    test('rejects local tool names', () {
      expect(isMcpQualifiedToolName('get_current_time'), isFalse);
      expect(parseMcpQualifiedToolName('get_current_time'), isNull);
      expect(parseMcpQualifiedToolName('mcp__only'), isNull);
    });
  });
}
