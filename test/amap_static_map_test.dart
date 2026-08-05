import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/features/agent/agent.dart';

void main() {
  test('builds static map url without exposing key in markdown tag', () {
    final tag = AmapStaticMap.buildMarkdownTag(
      latitude: 39.990464,
      longitude: 116.481485,
      zoom: 10,
    );
    expect(tag, '<amap_map lat="39.990464" lng="116.481485" zoom="10" />');
    expect(tag.contains('key='), isFalse);

    final url = AmapStaticMap.buildImageUrl(
      latitude: 39.990464,
      longitude: 116.481485,
      amapKey: 'secret-key',
      zoom: 10,
    );
    expect(url, contains('restapi.amap.com/v3/staticmap'));
    expect(url, contains('location=116.481485,39.990464'));
    expect(url, contains('size=750*300'));
    expect(url, contains('key=secret-key'));
  });

  test('parses amap_map tag attributes', () {
    final match = AmapStaticMap.tagPattern.firstMatch(
      '<amap_map lat="39.99" lng="116.48" zoom="8" />',
    );
    final attrs = AmapStaticMap.parseTagAttributes(match?.group(1) ?? '');

    expect(attrs, isNotNull);
    expect(attrs!.latitude, 39.99);
    expect(attrs.longitude, 116.48);
    expect(attrs.zoom, 8);
  });
}
