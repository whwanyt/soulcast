/// Weather background widget adapted from flutter_weather_bg (MIT).
/// Copyright (c) 2020–2026 xiaweizi — https://github.com/xiaweizi/flutter_weather_bg
library;

import 'package:flutter/material.dart';

import 'weather_cloud_bg.dart';
import 'weather_color_bg.dart';
import 'weather_night_star_bg.dart';
import 'weather_rain_snow_bg.dart';
import 'weather_thunder_bg.dart';
import 'weather_type.dart';

export 'weather_type.dart';

/// 天气动态背景入口：按 [weatherType] 组合渐变 / 云 / 雨雪 / 雷 / 星空。
class WeatherBg extends StatelessWidget {
  const WeatherBg({
    super.key,
    required this.weatherType,
    required this.width,
    required this.height,
  });

  final WeatherType weatherType;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return WeatherSizeInherited(
      size: Size(width, height),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _WeatherItemBg(
          key: ValueKey(weatherType),
          weatherType: weatherType,
          width: width,
          height: height,
        ),
      ),
    );
  }
}

class _WeatherItemBg extends StatelessWidget {
  const _WeatherItemBg({
    super.key,
    required this.weatherType,
    required this.width,
    required this.height,
  });

  final WeatherType weatherType;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          children: [
            WeatherColorBg(weatherType: weatherType),
            WeatherCloudBg(weatherType: weatherType),
            if (WeatherUtil.isSnowRain(weatherType))
              WeatherRainSnowBg(
                weatherType: weatherType,
                viewWidth: width,
                viewHeight: height,
              ),
            if (weatherType == WeatherType.thunder)
              WeatherThunderBg(weatherType: weatherType),
            if (weatherType == WeatherType.sunnyNight)
              WeatherNightStarBg(weatherType: weatherType),
          ],
        ),
      ),
    );
  }
}

/// 向子层传递画布尺寸。
class WeatherSizeInherited extends InheritedWidget {
  const WeatherSizeInherited({
    super.key,
    required super.child,
    required this.size,
  });

  final Size size;

  static WeatherSizeInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WeatherSizeInherited>();
  }

  @override
  bool updateShouldNotify(WeatherSizeInherited old) => old.size != size;
}
