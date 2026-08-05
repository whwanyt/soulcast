/// 高德静态地图 URL 与 markdown 标签辅助。
///
/// 标签不携带 API key；渲染时再从工具配置拼完整 URL。
class AmapStaticMap {
  const AmapStaticMap._();

  static const defaultZoom = 10;
  static const defaultSize = '750*300';
  static const tagName = 'amap_map';

  static final tagPattern = RegExp(
    r'<amap_map\s+([^>]*?)\s*/?>',
    caseSensitive: false,
  );

  static String buildMarkdownTag({
    required double latitude,
    required double longitude,
    int zoom = defaultZoom,
  }) {
    return '<$tagName lat="$latitude" lng="$longitude" zoom="$zoom" />';
  }

  static String buildImageUrl({
    required double latitude,
    required double longitude,
    required String amapKey,
    int zoom = defaultZoom,
    String size = defaultSize,
  }) {
    final location = '$longitude,$latitude';
    final markers = 'mid,,A:$location';
    // 高德示例使用未编码的逗号与 `*`；手动拼 query，避免 Uri 过度编码。
    return 'https://restapi.amap.com/v3/staticmap'
        '?location=$location'
        '&zoom=$zoom'
        '&size=$size'
        '&markers=$markers'
        '&key=${Uri.encodeQueryComponent(amapKey)}';
  }

  static AmapMapTagAttrs? parseTagAttributes(String rawAttributes) {
    final lat = _readDoubleAttr(rawAttributes, 'lat');
    final lng = _readDoubleAttr(rawAttributes, 'lng');
    if (lat == null || lng == null) {
      return null;
    }
    final zoom = _readIntAttr(rawAttributes, 'zoom') ?? defaultZoom;
    return AmapMapTagAttrs(latitude: lat, longitude: lng, zoom: zoom);
  }

  static double? _readDoubleAttr(String source, String name) {
    final match = RegExp(
      '$name\\s*=\\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(source);
    return double.tryParse(match?.group(1) ?? '');
  }

  static int? _readIntAttr(String source, String name) {
    final match = RegExp(
      '$name\\s*=\\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(source);
    return int.tryParse(match?.group(1) ?? '');
  }
}

/// 高德地图 Markdown 标签解析后的属性。
class AmapMapTagAttrs {
  const AmapMapTagAttrs({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });

  final double latitude;
  final double longitude;
  final int zoom;
}
