import 'dart:math';

/// Model class containing screen information.
class ScreenInfo {
  /// Screen width in logical pixels
  final double width;

  /// Screen height in logical pixels
  final double height;

  /// Screen width in physical pixels
  final double physicalWidth;

  /// Screen height in physical pixels
  final double physicalHeight;

  /// Device pixel ratio
  final double pixelRatio;

  /// Screen density in DPI
  final double density;

  /// Screen refresh rate in Hz (if available)
  final double? refreshRate;

  /// Whether the device has a notch or cutout
  final bool hasNotch;

  /// Screen orientation (portrait, landscape, etc.)
  final String orientation;

  /// Screen brightness (0.0 to 1.0, if available)
  final double? brightness;

  const ScreenInfo({
    required this.width,
    required this.height,
    required this.physicalWidth,
    required this.physicalHeight,
    required this.pixelRatio,
    required this.density,
    this.refreshRate,
    required this.hasNotch,
    required this.orientation,
    this.brightness,
  });

  /// Creates a ScreenInfo instance from a JSON map
  factory ScreenInfo.fromJson(Map<String, dynamic> json) => ScreenInfo(
    width: (json['width'] as num?)?.toDouble() ?? 0.0,
    height: (json['height'] as num?)?.toDouble() ?? 0.0,
    physicalWidth: (json['physicalWidth'] as num?)?.toDouble() ?? 0.0,
    physicalHeight: (json['physicalHeight'] as num?)?.toDouble() ?? 0.0,
    pixelRatio: (json['pixelRatio'] as num?)?.toDouble() ?? 1.0,
    density: (json['density'] as num?)?.toDouble() ?? 160.0,
    refreshRate: json['refreshRate'] != null
        ? (json['refreshRate'] as num).toDouble()
        : null,
    hasNotch: json['hasNotch'] ?? false,
    orientation: json['orientation'] ?? 'portrait',
    brightness: json['brightness'] != null
        ? (json['brightness'] as num).toDouble()
        : null,
  );

  /// Converts the ScreenInfo instance to a JSON map
  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'physicalWidth': physicalWidth,
    'physicalHeight': physicalHeight,
    'pixelRatio': pixelRatio,
    'density': density,
    'refreshRate': refreshRate,
    'hasNotch': hasNotch,
    'orientation': orientation,
    'brightness': brightness,
  };

  /// Returns screen size as string (e.g., "1080x1920")
  String get size => '${width.round()}x${height.round()}';

  /// Returns physical screen size as string (e.g., "1440x2560")
  String get physicalSize =>
      '${physicalWidth.round()}x${physicalHeight.round()}';

  /// Returns screen diagonal in inches (approximate)
  double get diagonalInches {
    final widthInches = physicalWidth / density;
    final heightInches = physicalHeight / density;
    return sqrt(widthInches * widthInches + heightInches * heightInches);
  }

  @override
  String toString() =>
      'ScreenInfo(size: $size, pixelRatio: $pixelRatio, density: ${density.round()}dpi, hasNotch: $hasNotch)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenInfo &&
        other.width == width &&
        other.height == height &&
        other.pixelRatio == pixelRatio &&
        other.density == density &&
        other.hasNotch == hasNotch;
  }

  @override
  int get hashCode =>
      width.hashCode ^
      height.hashCode ^
      pixelRatio.hashCode ^
      density.hashCode ^
      hasNotch.hashCode;
}
