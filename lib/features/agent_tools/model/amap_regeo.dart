/// 高德逆地理编码（regeo）HTTP API 辅助。
class AmapRegeo {
  const AmapRegeo._();

  static const endpoint = 'https://restapi.amap.com/v3/geocode/regeo';
  static const defaultRadiusMeters = 1000;
  static const extensionsBase = 'base';
  static const extensionsAll = 'all';

  static Uri buildUri({
    required String amapKey,
    required double longitude,
    required double latitude,
    required String extensions,
    int radius = defaultRadiusMeters,
  }) {
    return Uri.parse(endpoint).replace(
      queryParameters: <String, String>{
        'key': amapKey,
        'location': '$longitude,$latitude',
        'radius': '$radius',
        'extensions': extensions,
        'roadlevel': '0',
        'output': 'JSON',
      },
    );
  }

  static bool isValidExtensions(String value) {
    return value == extensionsBase || value == extensionsAll;
  }
}
