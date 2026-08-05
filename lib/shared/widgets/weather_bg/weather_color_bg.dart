import 'package:flutter/material.dart';

import 'weather_type.dart';

/// 颜色背景层。
class WeatherColorBg extends StatelessWidget {
  const WeatherColorBg({super.key, required this.weatherType, this.height});

  final WeatherType weatherType;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: WeatherUtil.getColor(weatherType),
          stops: const [0, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
