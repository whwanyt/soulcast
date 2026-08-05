import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/features/agent_tools/service/show_location_map_tool.dart';

void main() {
  test(
    'returns markdown tag when amap key and coordinates are valid',
    () async {
      final tool = ShowLocationMapTool(resolveAmapKey: () => 'test-key');

      final result = await tool.run(const {
        'latitude': 39.990464,
        'longitude': 116.481485,
        'zoom': 12,
      });

      expect(result['status'], 'success');
      expect(result['latitude'], 39.990464);
      expect(result['longitude'], 116.481485);
      expect(result['zoom'], 12);
      expect(
        result['markdown'],
        '<amap_map lat="39.990464" lng="116.481485" zoom="12" />',
      );
      expect(result.containsKey('imageUrl'), isFalse);
    },
  );

  test('fails when amap key is missing', () async {
    final tool = ShowLocationMapTool(resolveAmapKey: () => '  ');

    final result = await tool.run(const {
      'latitude': 39.990464,
      'longitude': 116.481485,
    });

    expect(result['status'], 'missing_amap_key');
    expect(result['message'], isA<String>());
  });

  test('fails when coordinates are invalid', () async {
    final tool = ShowLocationMapTool(resolveAmapKey: () => 'test-key');

    final result = await tool.run(const {
      'latitude': 'bad',
      'longitude': 116.0,
    });

    expect(result['status'], 'invalid_arguments');
  });
}
