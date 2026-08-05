import 'dart:math';

/// 设计稿基准宽（用来算 widthRatio）
const double kWeatherDesignWidth = 392.0;

/// 设计稿基准高（用来算 heightRatio）
const double kWeatherDesignHeight = 817.0;

/// 共享 Random，避免粒子系统每帧 new 一堆 Random 实例
final Random kWeatherRandom = Random();
