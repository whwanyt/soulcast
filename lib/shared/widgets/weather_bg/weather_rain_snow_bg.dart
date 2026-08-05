import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'weather_bg.dart';
import 'weather_constants.dart';
import 'weather_image_utils.dart';

/// 雨雪粒子动画层。
class WeatherRainSnowBg extends StatefulWidget {
  const WeatherRainSnowBg({
    super.key,
    required this.weatherType,
    required this.viewWidth,
    required this.viewHeight,
  });

  final WeatherType weatherType;
  final double viewWidth;
  final double viewHeight;

  @override
  State<WeatherRainSnowBg> createState() => _WeatherRainSnowBgState();
}

class _WeatherRainSnowBgState extends State<WeatherRainSnowBg>
    with SingleTickerProviderStateMixin {
  ui.Image? _rainImage;
  ui.Image? _snowImage;
  late final AnimationController _controller;
  final List<_RainSnowParams> _rainSnows = [];
  WeatherDataState _state = WeatherDataState.init;

  Future<void> _fetchImages() async {
    final rain = await WeatherImageUtils.getImage('assets/weather/rain.webp');
    final snow = await WeatherImageUtils.getImage('assets/weather/snow.webp');
    if (!mounted) {
      rain.dispose();
      snow.dispose();
      return;
    }
    _rainImage = rain;
    _snowImage = snow;
    _state = WeatherDataState.init;
    setState(() {});
  }

  void _initParams() {
    _state = WeatherDataState.loading;
    if (widget.viewWidth != 0 && widget.viewHeight != 0 && _rainSnows.isEmpty) {
      if (WeatherUtil.isSnowRain(widget.weatherType)) {
        final count = _particleCountFor(widget.weatherType);
        final size = WeatherSizeInherited.of(context)!.size;
        final widthRatio = size.width / kWeatherDesignWidth;
        final heightRatio = size.height / kWeatherDesignHeight;
        for (var i = 0; i < count; i++) {
          _rainSnows.add(
            _RainSnowParams(
              widget.viewWidth,
              widget.viewHeight,
              widget.weatherType,
            )..init(widthRatio, heightRatio),
          );
        }
      }
    }
    _controller.forward();
    _state = WeatherDataState.finish;
  }

  static int _particleCountFor(WeatherType type) {
    switch (type) {
      case WeatherType.lightRainy:
        return 70;
      case WeatherType.middleRainy:
        return 100;
      case WeatherType.heavyRainy:
      case WeatherType.thunder:
        return 200;
      case WeatherType.lightSnow:
        return 30;
      case WeatherType.middleSnow:
        return 100;
      case WeatherType.heavySnow:
        return 200;
      default:
        return 0;
    }
  }

  @override
  void didUpdateWidget(WeatherRainSnowBg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherType != widget.weatherType ||
        oldWidget.viewWidth != widget.viewWidth ||
        oldWidget.viewHeight != widget.viewHeight) {
      _rainSnows.clear();
      _initParams();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(minutes: 1), vsync: this)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _controller.repeat();
            }
          });
    _fetchImages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _rainImage?.dispose();
    _snowImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == WeatherDataState.init) {
      _initParams();
    }
    if (_state != WeatherDataState.finish) {
      return const SizedBox.shrink();
    }
    return CustomPaint(painter: _RainSnowPainter(this, _controller));
  }
}

class _RainSnowPainter extends CustomPainter {
  _RainSnowPainter(this._state, Listenable repaint) : super(repaint: repaint);

  final _WeatherRainSnowBgState _state;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final weatherType = _state.widget.weatherType;
    if (WeatherUtil.isSnow(weatherType) && _state._snowImage != null) {
      _drawParticles(canvas, _state._snowImage!, true);
    } else if (WeatherUtil.isRainy(weatherType) && _state._rainImage != null) {
      _drawParticles(canvas, _state._rainImage!, false);
    }
  }

  void _drawParticles(Canvas canvas, ui.Image image, bool isSnow) {
    for (final particle in _state._rainSnows) {
      _move(particle, isSnow);
      canvas.save();
      canvas.scale(particle.scale);
      _paint.colorFilter = ColorFilter.mode(
        Color.fromRGBO(255, 255, 255, particle.alpha),
        BlendMode.modulate,
      );
      canvas.drawImage(image, Offset(particle.x, particle.y), _paint);
      canvas.restore();
    }
  }

  void _move(_RainSnowParams particle, bool isSnow) {
    particle.y += particle.speed;
    if (isSnow) {
      final offsetX =
          sin(particle.y / (300 + 50 * particle.alpha)) *
          (1 + 0.5 * particle.alpha) *
          particle.widthRatio;
      particle.x += offsetX;
    }
    if (particle.y > particle.height / particle.scale) {
      particle.y = -particle.height * particle.scale;
      if (!isSnow && _state._rainImage != null) {
        particle.y = -_state._rainImage!.height.toDouble();
      }
      particle.reset();
    }
  }

  @override
  bool shouldRepaint(covariant _RainSnowPainter old) => true;
}

class _RainSnowParams {
  _RainSnowParams(this.width, this.height, this.weatherType);

  double x = 0;
  double y = 0;
  double speed = 0;
  double scale = 1;
  final double width;
  final double height;
  double alpha = 1;
  final WeatherType weatherType;
  double widthRatio = 1;
  double heightRatio = 1;

  void init(double widthRatio, double heightRatio) {
    this.widthRatio = widthRatio;
    this.heightRatio = max(heightRatio, 0.65);
    reset();
    y = kWeatherRandom.nextInt(800 ~/ scale).toDouble();
  }

  void reset() {
    final ratio = _speedRatio(weatherType);
    final random = 0.4 + 0.12 * kWeatherRandom.nextDouble() * 5;
    if (WeatherUtil.isRainy(weatherType)) {
      scale = random * 1.2;
      speed = 30 * random * ratio * heightRatio;
      alpha = random * 0.6;
    } else {
      scale = random * 0.8 * heightRatio;
      speed = 8 * random * ratio * heightRatio;
      alpha = random;
    }
    x =
        kWeatherRandom.nextInt(width * 1.2 ~/ scale).toDouble() -
        width * 0.1 ~/ scale;
  }

  static double _speedRatio(WeatherType type) {
    switch (type) {
      case WeatherType.lightRainy:
      case WeatherType.lightSnow:
        return 0.5;
      case WeatherType.middleRainy:
      case WeatherType.middleSnow:
        return 0.75;
      case WeatherType.heavyRainy:
      case WeatherType.thunder:
      case WeatherType.heavySnow:
        return 1;
      default:
        return 1;
    }
  }
}
