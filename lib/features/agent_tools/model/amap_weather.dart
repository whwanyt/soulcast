import 'package:soulcast/shared/widgets/weather_bg/weather_bg.dart';

/// 高德天气查询（weatherInfo）与 markdown 标签辅助。
///
/// 工具请求时使用 Key；返回的标签只携带实况字段，渲染时不再请求接口。
class AmapWeather {
  const AmapWeather._();

  static const endpoint = 'https://restapi.amap.com/v3/weather/weatherInfo';
  static const tagName = 'amap_weather';
  static const extensionsBase = 'base';
  static const defaultBg = WeatherType.cloudy;

  static final tagPattern = RegExp(
    r'<amap_weather\s+([^>]*?)\s*/?>',
    caseSensitive: false,
  );

  static Uri buildUri({required String amapKey, required String city}) {
    return Uri.parse(endpoint).replace(
      queryParameters: <String, String>{
        'key': amapKey,
        'city': city,
        'extensions': extensionsBase,
        'output': 'JSON',
      },
    );
  }

  static String buildMarkdownTag(AmapWeatherLive live) {
    return '<$tagName'
        ' province="${_escapeAttr(live.province)}"'
        ' city="${_escapeAttr(live.city)}"'
        ' adcode="${_escapeAttr(live.adcode)}"'
        ' weather="${_escapeAttr(live.weather)}"'
        ' temperature="${_escapeAttr(live.temperature)}"'
        ' winddirection="${_escapeAttr(live.windDirection)}"'
        ' windpower="${_escapeAttr(live.windPower)}"'
        ' humidity="${_escapeAttr(live.humidity)}"'
        ' reporttime="${_escapeAttr(live.reportTime)}"'
        ' bg="${_escapeAttr(live.bg)}"'
        ' />';
  }

  static AmapWeatherLive? parseTagAttributes(String rawAttributes) {
    final weather = _readAttr(rawAttributes, 'weather');
    final temperature = _readAttr(rawAttributes, 'temperature');
    if (weather == null || temperature == null) {
      return null;
    }
    final bgAttr = _readAttr(rawAttributes, 'bg');
    return AmapWeatherLive(
      province: _readAttr(rawAttributes, 'province') ?? '',
      city: _readAttr(rawAttributes, 'city') ?? '',
      adcode: _readAttr(rawAttributes, 'adcode') ?? '',
      weather: weather,
      temperature: temperature,
      windDirection: _readAttr(rawAttributes, 'winddirection') ?? '',
      windPower: _readAttr(rawAttributes, 'windpower') ?? '',
      humidity: _readAttr(rawAttributes, 'humidity') ?? '',
      reportTime: _readAttr(rawAttributes, 'reporttime') ?? '',
      bg: resolveBg(weather, bg: bgAttr).name,
    );
  }

  static AmapWeatherLive? liveFromJson(Map<String, dynamic> json) {
    final weather = _asNonEmptyString(json['weather']);
    final temperature = _asNonEmptyString(json['temperature']);
    if (weather == null || temperature == null) {
      return null;
    }
    final bgAttr = _asNonEmptyString(json['bg']);
    return AmapWeatherLive(
      province: _asNonEmptyString(json['province']) ?? '',
      city: _asNonEmptyString(json['city']) ?? '',
      adcode: _asNonEmptyString(json['adcode']) ?? '',
      weather: weather,
      temperature: temperature,
      windDirection: _asNonEmptyString(json['winddirection']) ?? '',
      windPower: _asNonEmptyString(json['windpower']) ?? '',
      humidity: _asNonEmptyString(json['humidity']) ?? '',
      reportTime: _asNonEmptyString(json['reporttime']) ?? '',
      bg: resolveBg(weather, bg: bgAttr).name,
    );
  }

  /// 优先合法 [bg]；否则按高德 `weather` 中文文案映射；仍失败则 [defaultBg]。
  static WeatherType resolveBg(String weatherText, {String? bg}) {
    final parsed = WeatherType.tryParse(bg);
    if (parsed != null) {
      return parsed;
    }
    return _mapWeatherText(weatherText) ?? defaultBg;
  }

  static WeatherType? _mapWeatherText(String weatherText) {
    final text = weatherText.trim();
    if (text.isEmpty) {
      return null;
    }

    if (text.contains('雷')) {
      return WeatherType.thunder;
    }
    if (text.contains('暴雨') || text.contains('大雨')) {
      return WeatherType.heavyRainy;
    }
    if (text.contains('中雨')) {
      return WeatherType.middleRainy;
    }
    if (text.contains('小雨') ||
        text.contains('阵雨') ||
        text.contains('毛毛雨') ||
        text == '雨') {
      return WeatherType.lightRainy;
    }
    if (text.contains('雨')) {
      return WeatherType.middleRainy;
    }
    if (text.contains('暴雪') || text.contains('大雪')) {
      return WeatherType.heavySnow;
    }
    if (text.contains('中雪')) {
      return WeatherType.middleSnow;
    }
    if (text.contains('小雪') || text == '雪' || text.contains('阵雪')) {
      return WeatherType.lightSnow;
    }
    if (text.contains('雪')) {
      return WeatherType.middleSnow;
    }
    if (text.contains('霾')) {
      return WeatherType.hazy;
    }
    if (text.contains('雾')) {
      return WeatherType.foggy;
    }
    if (text.contains('浮尘') || text.contains('扬沙') || text.contains('沙尘')) {
      return WeatherType.dusty;
    }
    if (text.contains('阴')) {
      return WeatherType.overcast;
    }
    if (text.contains('多云')) {
      return WeatherType.cloudy;
    }
    if (text.contains('晴')) {
      return WeatherType.sunny;
    }
    return null;
  }

  static String? _readAttr(String source, String name) {
    final match = RegExp(
      '$name\\s*=\\s*"([^"]*)"',
      caseSensitive: false,
    ).firstMatch(source);
    final raw = match?.group(1);
    if (raw == null) {
      return null;
    }
    return _unescapeAttr(raw);
  }

  static String _escapeAttr(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  static String _unescapeAttr(String value) {
    return value
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
  }

  static String? _asNonEmptyString(Object? value) {
    if (value == null) {
      return null;
    }
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }
}

/// 高德天气实况字段。
class AmapWeatherLive {
  const AmapWeatherLive({
    required this.province,
    required this.city,
    required this.adcode,
    required this.weather,
    required this.temperature,
    required this.windDirection,
    required this.windPower,
    required this.humidity,
    required this.reportTime,
    required this.bg,
  });

  final String province;
  final String city;
  final String adcode;
  final String weather;
  final String temperature;
  final String windDirection;
  final String windPower;
  final String humidity;
  final String reportTime;

  /// 背景类型枚举名，如 `sunny`、`lightRainy`。
  final String bg;

  Map<String, dynamic> toJson() {
    return {
      'province': province,
      'city': city,
      'adcode': adcode,
      'weather': weather,
      'temperature': temperature,
      'winddirection': windDirection,
      'windpower': windPower,
      'humidity': humidity,
      'reporttime': reportTime,
      'bg': bg,
    };
  }

  AmapWeatherLive copyWith({String? bg}) {
    return AmapWeatherLive(
      province: province,
      city: city,
      adcode: adcode,
      weather: weather,
      temperature: temperature,
      windDirection: windDirection,
      windPower: windPower,
      humidity: humidity,
      reportTime: reportTime,
      bg: bg ?? this.bg,
    );
  }
}
