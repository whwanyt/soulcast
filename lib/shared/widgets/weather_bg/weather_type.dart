import 'dart:ui' show Color;

/// 天气背景类型（15 种）。
enum WeatherType {
  heavyRainy,
  heavySnow,
  middleSnow,
  thunder,
  lightRainy,
  lightSnow,
  sunnyNight,
  sunny,
  cloudy,
  cloudyNight,
  middleRainy,
  overcast,
  hazy,
  foggy,
  dusty;

  /// 解析枚举名（如 `sunny`、`lightRainy`）；非法值返回 null。
  static WeatherType? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final name = raw.trim();
    if (name.isEmpty) {
      return null;
    }
    for (final value in WeatherType.values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}

/// 资源加载状态。
enum WeatherDataState { init, loading, finish }

/// 天气背景工具。
class WeatherUtil {
  const WeatherUtil._();

  static bool isSnowRain(WeatherType weatherType) {
    return isRainy(weatherType) || isSnow(weatherType);
  }

  static bool isRainy(WeatherType weatherType) {
    return weatherType == WeatherType.lightRainy ||
        weatherType == WeatherType.middleRainy ||
        weatherType == WeatherType.heavyRainy ||
        weatherType == WeatherType.thunder;
  }

  static bool isSnow(WeatherType weatherType) {
    return weatherType == WeatherType.lightSnow ||
        weatherType == WeatherType.middleSnow ||
        weatherType == WeatherType.heavySnow;
  }

  static List<Color> getColor(WeatherType weatherType) {
    switch (weatherType) {
      case WeatherType.sunny:
        return [const Color(0xFF0071D1), const Color(0xFF6DA6E4)];
      case WeatherType.sunnyNight:
        return [const Color(0xFF061E74), const Color(0xFF275E9A)];
      case WeatherType.cloudy:
        return [const Color(0xFF5C82C1), const Color(0xFF95B1DB)];
      case WeatherType.cloudyNight:
        return [const Color(0xFF2C3A60), const Color(0xFF4B6685)];
      case WeatherType.overcast:
        return [const Color(0xFF8FA3C0), const Color(0xFF8C9FB1)];
      case WeatherType.lightRainy:
        return [const Color(0xFF556782), const Color(0xFF7c8b99)];
      case WeatherType.middleRainy:
        return [const Color(0xFF3A4B65), const Color(0xFF495764)];
      case WeatherType.heavyRainy:
      case WeatherType.thunder:
        return [const Color(0xFF3B434E), const Color(0xFF565D66)];
      case WeatherType.hazy:
        return [const Color(0xFF989898), const Color(0xFF4B4B4B)];
      case WeatherType.foggy:
        return [const Color(0xFFA6B3C2), const Color(0xFF737F88)];
      case WeatherType.lightSnow:
        return [const Color(0xFF6989BA), const Color(0xFF9DB0CE)];
      case WeatherType.middleSnow:
        return [const Color(0xFF8595AD), const Color(0xFF95A4BF)];
      case WeatherType.heavySnow:
        return [const Color(0xFF98A2BC), const Color(0xFFA7ADBF)];
      case WeatherType.dusty:
        return [const Color(0xFFB99D79), const Color(0xFF6C5635)];
    }
  }
}
