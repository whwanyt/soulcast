import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/features/mcp/mcp.dart';

void main() {
  group('mapMcpCallToolResultData', () {
    test('maps single text content', () {
      final payload = mapMcpCallToolResultData(
        isError: false,
        content: [
          {'type': 'text', 'text': 'hello'},
        ],
      );
      expect(payload['text'], 'hello');
    });

    test('maps structured content', () {
      final payload = mapMcpCallToolResultData(
        isError: false,
        content: const [],
        structuredContent: {'ok': true},
      );
      expect(payload['structuredContent'], {'ok': true});
    });

    test('throws on error result', () {
      expect(
        () => mapMcpCallToolResultData(
          isError: true,
          content: [
            {'type': 'text', 'text': 'boom'},
          ],
        ),
        throwsA(isA<McpToolCallException>()),
      );
    });
  });
}
