import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// 将 asset 转为绘制用的 [ui.Image]。
class WeatherImageUtils {
  const WeatherImageUtils._();

  static Future<ui.Image> getImage(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
