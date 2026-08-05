import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'weather_bg.dart';
import 'weather_constants.dart';
import 'weather_image_utils.dart';

/// 云层 / 太阳绘制。
class WeatherCloudBg extends StatefulWidget {
  const WeatherCloudBg({super.key, required this.weatherType});

  final WeatherType weatherType;

  @override
  State<WeatherCloudBg> createState() => _WeatherCloudBgState();
}

class _WeatherCloudBgState extends State<WeatherCloudBg> {
  ui.Image? _cloudImage;
  ui.Image? _sunImage;

  Future<void> _fetchImages() async {
    final cloud = await WeatherImageUtils.getImage('assets/weather/cloud.webp');
    final sun = await WeatherImageUtils.getImage('assets/weather/sun.webp');
    if (!mounted) {
      cloud.dispose();
      sun.dispose();
      return;
    }
    setState(() {
      _cloudImage = cloud;
      _sunImage = sun;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  @override
  void dispose() {
    _cloudImage?.dispose();
    _sunImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cloud = _cloudImage;
    final sun = _sunImage;
    if (cloud == null || sun == null) {
      return const SizedBox.shrink();
    }
    final size = WeatherSizeInherited.of(context)!.size;
    return CustomPaint(
      painter: _CloudPainter(
        cloudImage: cloud,
        sunImage: sun,
        weatherType: widget.weatherType,
        widthRatio: size.width / kWeatherDesignWidth,
        width: size.width,
      ),
    );
  }
}

class _CloudLayer {
  const _CloudLayer({
    required this.colorMatrix,
    required this.scaleFactor,
    required this.offsetsOf,
  });

  final List<double> colorMatrix;
  final double scaleFactor;
  final List<Offset> Function(ui.Image image) offsetsOf;
}

const List<double> _mClearAlpha90 = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 0.9, 0, //
];
const List<double> _mCloudyNight = [
  0.32, 0, 0, 0, 0, //
  0, 0.39, 0, 0, 0, //
  0, 0, 0.52, 0, 0, //
  0, 0, 0, 0.9, 0, //
];
const List<double> _mOvercast = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 0.7, 0, //
];
const List<double> _mLightRainy = [
  0.45, 0, 0, 0, 0, //
  0, 0.52, 0, 0, 0, //
  0, 0, 0.6, 0, 0, //
  0, 0, 0, 1, 0, //
];
const List<double> _mMiddleRainy = [
  0.16, 0, 0, 0, 0, //
  0, 0.22, 0, 0, 0, //
  0, 0, 0.31, 0, 0, //
  0, 0, 0, 1, 0, //
];
const List<double> _mHeavyRainy = [
  0.19, 0, 0, 0, 0, //
  0, 0.2, 0, 0, 0, //
  0, 0, 0.22, 0, 0, //
  0, 0, 0, 1, 0, //
];
const List<double> _mHazy = [
  0.67, 0, 0, 0, 0, //
  0, 0.67, 0, 0, 0, //
  0, 0, 0.67, 0, 0, //
  0, 0, 0, 1, 0, //
];
const List<double> _mFoggy = [
  0.75, 0, 0, 0, 0, //
  0, 0.77, 0, 0, 0, //
  0, 0, 0.82, 0, 0, //
  0, 0, 0, 1, 0, //
];
const List<double> _mDusty = [
  0.62, 0, 0, 0, 0, //
  0, 0.55, 0, 0, 0, //
  0, 0, 0.45, 0, 0, //
  0, 0, 0, 1, 0, //
];
const List<double> _mLightSnow = [
  0.67, 0, 0, 0, 0, //
  0, 0.75, 0, 0, 0, //
  0, 0, 0.87, 0, 0, //
  0, 0, 0, 1, 0, //
];
const List<double> _mMiddleSnow = [
  0.7, 0, 0, 0, 0, //
  0, 0.77, 0, 0, 0, //
  0, 0, 0.87, 0, 0, //
  0, 0, 0, 1, 0, //
];
const List<double> _mHeavySnow = [
  0.74, 0, 0, 0, 0, //
  0, 0.74, 0, 0, 0, //
  0, 0, 0.81, 0, 0, //
  0, 0, 0, 1, 0, //
];

List<Offset> _threeCloudOffsets(ui.Image image) => [
  const Offset(0, -200),
  Offset(-image.width / 2, -130),
  const Offset(100, 0),
];

List<Offset> _twoSnowOffsets(ui.Image image) => const [
  Offset(-380, -100),
  Offset(0, -170),
];

List<Offset> _threeRainOffsets(ui.Image image) => const [
  Offset(-380, -150),
  Offset(0, -60),
  Offset(0, 60),
];

List<Offset> _singleHugeOffset(ui.Image image) => [
  Offset(-image.width * 0.5, -200),
];

final Map<WeatherType, List<_CloudLayer>> _kSpecs = {
  WeatherType.cloudy: [
    _CloudLayer(
      colorMatrix: _mClearAlpha90,
      scaleFactor: 0.8,
      offsetsOf: _threeCloudOffsets,
    ),
  ],
  WeatherType.cloudyNight: [
    _CloudLayer(
      colorMatrix: _mCloudyNight,
      scaleFactor: 0.8,
      offsetsOf: _threeCloudOffsets,
    ),
  ],
  WeatherType.overcast: [
    _CloudLayer(
      colorMatrix: _mOvercast,
      scaleFactor: 0.8,
      offsetsOf: _threeCloudOffsets,
    ),
  ],
  WeatherType.lightRainy: [
    _CloudLayer(
      colorMatrix: _mLightRainy,
      scaleFactor: 0.8,
      offsetsOf: _threeRainOffsets,
    ),
  ],
  WeatherType.middleRainy: [
    _CloudLayer(
      colorMatrix: _mMiddleRainy,
      scaleFactor: 0.8,
      offsetsOf: _threeRainOffsets,
    ),
  ],
  WeatherType.heavyRainy: [
    _CloudLayer(
      colorMatrix: _mHeavyRainy,
      scaleFactor: 0.8,
      offsetsOf: _threeRainOffsets,
    ),
  ],
  WeatherType.thunder: [
    _CloudLayer(
      colorMatrix: _mHeavyRainy,
      scaleFactor: 0.8,
      offsetsOf: _threeRainOffsets,
    ),
  ],
  WeatherType.hazy: [
    _CloudLayer(
      colorMatrix: _mHazy,
      scaleFactor: 2.0,
      offsetsOf: _singleHugeOffset,
    ),
  ],
  WeatherType.foggy: [
    _CloudLayer(
      colorMatrix: _mFoggy,
      scaleFactor: 2.0,
      offsetsOf: _singleHugeOffset,
    ),
  ],
  WeatherType.dusty: [
    _CloudLayer(
      colorMatrix: _mDusty,
      scaleFactor: 2.0,
      offsetsOf: _singleHugeOffset,
    ),
  ],
  WeatherType.lightSnow: [
    _CloudLayer(
      colorMatrix: _mLightSnow,
      scaleFactor: 0.8,
      offsetsOf: _twoSnowOffsets,
    ),
  ],
  WeatherType.middleSnow: [
    _CloudLayer(
      colorMatrix: _mMiddleSnow,
      scaleFactor: 0.8,
      offsetsOf: _twoSnowOffsets,
    ),
  ],
  WeatherType.heavySnow: [
    _CloudLayer(
      colorMatrix: _mHeavySnow,
      scaleFactor: 0.8,
      offsetsOf: _twoSnowOffsets,
    ),
  ],
};

class _CloudPainter extends CustomPainter {
  _CloudPainter({
    required this.cloudImage,
    required this.sunImage,
    required this.weatherType,
    required this.widthRatio,
    required this.width,
  });

  final ui.Image cloudImage;
  final ui.Image sunImage;
  final WeatherType weatherType;
  final double widthRatio;
  final double width;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (weatherType == WeatherType.sunny) {
      _drawSunny(canvas);
      return;
    }
    final layers = _kSpecs[weatherType];
    if (layers == null) {
      return;
    }
    for (final layer in layers) {
      _drawLayer(canvas, layer);
    }
  }

  void _drawSunny(Canvas canvas) {
    _paint
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
      ..colorFilter = null;
    canvas.save();
    final sunScale = 1.2 * widthRatio;
    canvas.scale(sunScale, sunScale);
    final sunOffset = Offset(
      width - sunImage.width.toDouble() * sunScale,
      -sunImage.width.toDouble() / 2,
    );
    canvas.drawImage(sunImage, sunOffset, _paint);
    canvas.restore();

    canvas.save();
    final cloudScale = 0.6 * widthRatio;
    canvas.scale(cloudScale, cloudScale);
    canvas.drawImage(cloudImage, const Offset(-100, -100), _paint);
    canvas.restore();
  }

  void _drawLayer(Canvas canvas, _CloudLayer layer) {
    _paint
      ..maskFilter = null
      ..colorFilter = ColorFilter.matrix(layer.colorMatrix);

    final offsets = layer.offsetsOf(cloudImage);
    final scale = layer.scaleFactor * widthRatio;

    canvas.save();
    canvas.scale(scale, scale);
    for (final off in offsets) {
      canvas.drawImage(cloudImage, off, _paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CloudPainter old) =>
      old.weatherType != weatherType ||
      old.widthRatio != widthRatio ||
      old.width != width ||
      old.cloudImage != cloudImage ||
      old.sunImage != sunImage;
}
