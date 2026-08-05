import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'weather_bg.dart';
import 'weather_constants.dart';
import 'weather_image_utils.dart';

/// 雷暴闪电动画层。
class WeatherThunderBg extends StatefulWidget {
  const WeatherThunderBg({super.key, required this.weatherType});

  final WeatherType weatherType;

  @override
  State<WeatherThunderBg> createState() => _WeatherThunderBgState();
}

class _WeatherThunderBgState extends State<WeatherThunderBg>
    with SingleTickerProviderStateMixin {
  static const int _imageCount = 5;
  static const int _boltCount = 3;

  final List<ui.Image> _images = [];
  late final AnimationController _controller;
  final List<_ThunderParams> _thunderParams = [];
  WeatherDataState _state = WeatherDataState.init;

  Future<void> _fetchImages() async {
    final futures = List.generate(
      _imageCount,
      (i) => WeatherImageUtils.getImage('assets/weather/lightning$i.webp'),
    );
    final images = await Future.wait(futures);
    if (!mounted) {
      for (final image in images) {
        image.dispose();
      }
      return;
    }
    _images
      ..clear()
      ..addAll(images);
    _state = WeatherDataState.init;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchImages();
  }

  void _setupAnimations() {
    _controller =
        AnimationController(duration: const Duration(seconds: 3), vsync: this)
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed) {
              return;
            }
            _controller.reset();
            Future.delayed(const Duration(milliseconds: 50), () {
              if (!mounted) {
                return;
              }
              _resetThunderParams();
              _controller.forward();
            });
          });

    for (var i = 0; i < _boltCount; i++) {
      final interval = _intervals[i];
      final animation =
          TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween(
                begin: 0.0,
                end: 1.0,
              ).chain(CurveTween(curve: Curves.easeIn)),
              weight: 1,
            ),
            TweenSequenceItem(
              tween: Tween(
                begin: 1.0,
                end: 0.0,
              ).chain(CurveTween(curve: Curves.easeIn)),
              weight: 3,
            ),
          ]).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(interval.$1, interval.$2, curve: Curves.ease),
            ),
          );
      animation.addListener(() {
        if (_thunderParams.length > i) {
          _thunderParams[i].alpha = animation.value;
        }
      });
    }
  }

  static const List<(double, double)> _intervals = [
    (0.0, 0.3),
    (0.2, 0.5),
    (0.6, 0.9),
  ];

  @override
  void dispose() {
    _controller.dispose();
    for (final image in _images) {
      image.dispose();
    }
    super.dispose();
  }

  void _resetThunderParams() {
    if (_images.isEmpty) {
      return;
    }
    _state = WeatherDataState.loading;
    final size = WeatherSizeInherited.of(context)!.size;
    final width = size.width;
    final height = size.height;
    final widthRatio = width / kWeatherDesignWidth;

    if (_thunderParams.isEmpty) {
      for (var i = 0; i < _boltCount; i++) {
        _thunderParams.add(
          _ThunderParams(
            _images[kWeatherRandom.nextInt(_imageCount)],
            width,
            height,
            widthRatio,
          ),
        );
      }
    } else {
      for (final params in _thunderParams) {
        params.image = _images[kWeatherRandom.nextInt(_imageCount)];
      }
    }
    for (final params in _thunderParams) {
      params.reset();
    }
    _controller.forward();
    _state = WeatherDataState.finish;
  }

  @override
  Widget build(BuildContext context) {
    if (_state == WeatherDataState.init && _images.isNotEmpty) {
      _resetThunderParams();
    }
    if (_state != WeatherDataState.finish ||
        _thunderParams.isEmpty ||
        widget.weatherType != WeatherType.thunder) {
      return const SizedBox.shrink();
    }
    return CustomPaint(painter: _ThunderPainter(_thunderParams, _controller));
  }
}

class _ThunderPainter extends CustomPainter {
  _ThunderPainter(this.thunderParams, Listenable repaint)
    : super(repaint: repaint);

  final List<_ThunderParams> thunderParams;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (final params in thunderParams) {
      _drawThunder(params, canvas);
    }
  }

  void _drawThunder(_ThunderParams params, Canvas canvas) {
    canvas.save();
    _paint.colorFilter = ColorFilter.mode(
      Color.fromRGBO(255, 255, 255, params.alpha),
      BlendMode.modulate,
    );
    canvas.scale(params.widthRatio * 1.2);
    canvas.drawImage(params.image, Offset(params.x, params.y), _paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThunderPainter old) => true;
}

class _ThunderParams {
  _ThunderParams(this.image, this.width, this.height, this.widthRatio);

  ui.Image image;
  double x = 0;
  double y = 0;
  double alpha = 0;
  final double width;
  final double height;
  final double widthRatio;

  int get imgWidth => image.width;

  void reset() {
    x = kWeatherRandom.nextDouble() * 0.5 * widthRatio - 1 / 3 * imgWidth;
    y = kWeatherRandom.nextDouble() * -0.05 * height;
    alpha = 0;
  }
}
