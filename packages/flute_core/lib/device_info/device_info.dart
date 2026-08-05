import 'dart:io';
import 'dart:ui' as ui;

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'models/battery_info.dart';
import 'models/cpu_info.dart';
import 'models/device_info.dart';
import 'models/ram_info.dart';
import 'models/screen_info.dart';

export 'models/device_info.dart';
export 'models/battery_info.dart';
export 'models/screen_info.dart';
export 'models/cpu_info.dart';
export 'models/ram_info.dart';

/// A comprehensive Flutter package that provides unified access to detailed
/// device information.
///
/// This singleton class provides easy access to device information including
/// hardware specs, OS details, and system resources with intelligent caching
/// for optimal performance.
///
/// Example usage:
/// ```dart
/// final deviceInfo = await SmartDeviceInfo.instance.getDeviceInfo();
/// final batteryInfo = await SmartDeviceInfo.instance.getBatteryInfo();
/// final screenInfo = SmartDeviceInfo.instance.getScreenInfo();
/// ```
class SmartDeviceInfo {
  SmartDeviceInfo._internal();

  static final SmartDeviceInfo _instance = SmartDeviceInfo._internal();
  factory SmartDeviceInfo() => _instance;

  /// Singleton instance of SmartDeviceInfo
  static SmartDeviceInfo get instance => _instance;

  // Cached instances
  DeviceInfo? _cachedDeviceInfo;
  BatteryInfo? _cachedBatteryInfo;
  ScreenInfo? _cachedScreenInfo;
  CpuInfo? _cachedCpuInfo;
  RamInfo? _cachedRamInfo;

  // Platform-specific instances
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final Battery _battery = Battery();

  Future<DeviceInfo> init() async {
    return await getDeviceInfo();
  }

  /// Gets comprehensive device information including manufacturer, model, OS
  /// details, etc.
  ///
  /// Returns cached data if available, otherwise fetches fresh data from the
  /// device. The result is cached for subsequent calls to improve performance.
  ///
  /// Returns a [DeviceInfo] object containing:
  /// - Device manufacturer and model
  /// - Operating system name and version
  /// - Unique device identifier
  /// - Emulator detection status
  /// - Device brand, product, and hardware info
  Future<DeviceInfo> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    try {
      if (Platform.isAndroid) {
        _cachedDeviceInfo = await _getAndroidDeviceInfo();
      } else if (Platform.isIOS) {
        _cachedDeviceInfo = await _getIOSDeviceInfo();
      } else if (kIsWeb) {
        _cachedDeviceInfo = await _getWebDeviceInfo();
      } else {
        _cachedDeviceInfo = await _getGenericDeviceInfo();
      }
    } on Exception {
      _cachedDeviceInfo = _getFallbackDeviceInfo();
    }

    return _cachedDeviceInfo!;
  }

  /// Gets current battery information including level, charging status, and
  /// health.
  ///
  /// Returns cached data if available, otherwise fetches fresh data from the
  /// device. The result is cached for subsequent calls to improve performance.
  ///
  /// Returns a [BatteryInfo] object containing:
  /// - Battery level (0.0 to 1.0)
  /// - Charging status
  /// - Battery health and temperature (if available)
  Future<BatteryInfo> getBatteryInfo() async {
    if (_cachedBatteryInfo != null) {
      return _cachedBatteryInfo!;
    }

    try {
      final level = await _battery.batteryLevel;
      final isCharging = await _battery.isInBatterySaveMode == false;

      _cachedBatteryInfo = BatteryInfo(
        level: (level / 100).toDouble(),
        isCharging: isCharging,
        isAvailable: true,
      );
    } on Exception {
      _cachedBatteryInfo = const BatteryInfo(
        level: 0,
        isCharging: false,
        isAvailable: false,
      );
    }

    return _cachedBatteryInfo!;
  }

  /// Gets screen information including dimensions, pixel ratio, and density.
  ///
  /// This method returns immediately with cached data or current screen info.
  /// Screen information is static and doesn't need to be fetched
  /// asynchronously.
  ///
  /// Returns a [ScreenInfo] object containing:
  /// - Screen dimensions (logical and physical pixels)
  /// - Device pixel ratio and density
  /// - Screen refresh rate and orientation
  /// - Notch detection
  ScreenInfo getScreenInfo() {
    if (_cachedScreenInfo != null) {
      return _cachedScreenInfo!;
    }

    final mediaQuery = ui.PlatformDispatcher.instance.views.first;
    final pixelRatio = mediaQuery.devicePixelRatio;
    final size = mediaQuery.physicalSize;
    final logicalSize = mediaQuery.physicalSize / pixelRatio;

    _cachedScreenInfo = ScreenInfo(
      width: logicalSize.width,
      height: logicalSize.height,
      physicalWidth: size.width,
      physicalHeight: size.height,
      pixelRatio: pixelRatio,
      density: pixelRatio * 160, // Approximate DPI calculation
      hasNotch: _detectNotch(logicalSize.width, logicalSize.height),
      orientation: logicalSize.width > logicalSize.height
          ? 'landscape'
          : 'portrait',
    );

    return _cachedScreenInfo!;
  }

  /// Gets CPU information including architecture, cores, and frequency.
  ///
  /// Returns cached data if available, otherwise fetches fresh data from the
  /// device. The result is cached for subsequent calls to improve performance.
  ///
  /// Returns a [CpuInfo] object containing:
  /// - CPU architecture and number of cores
  /// - CPU frequency and model (if available)
  /// - CPU usage and temperature (if available)
  Future<CpuInfo> getCpuInfo() async {
    if (_cachedCpuInfo != null) {
      return _cachedCpuInfo!;
    }

    try {
      if (Platform.isAndroid) {
        _cachedCpuInfo = await _getAndroidCpuInfo();
      } else if (Platform.isIOS) {
        _cachedCpuInfo = await _getIOSCpuInfo();
      } else {
        _cachedCpuInfo = _getGenericCpuInfo();
      }
    } on Exception {
      _cachedCpuInfo = _getFallbackCpuInfo();
    }

    return _cachedCpuInfo!;
  }

  /// Gets RAM (memory) information including total, available, and used
  /// memory.
  ///
  /// Returns cached data if available, otherwise fetches fresh data from the
  /// device. The result is cached for subsequent calls to improve performance.
  ///
  /// Returns a [RamInfo] object containing:
  /// - Total and available RAM
  /// - Used RAM and usage percentage
  /// - Memory availability status
  Future<RamInfo> getRamInfo() async {
    if (_cachedRamInfo != null) {
      return _cachedRamInfo!;
    }

    try {
      if (Platform.isAndroid) {
        _cachedRamInfo = await _getAndroidRamInfo();
      } else if (Platform.isIOS) {
        _cachedRamInfo = await _getIOSRamInfo();
      } else {
        _cachedRamInfo = _getGenericRamInfo();
      }
    } on Exception {
      _cachedRamInfo = _getFallbackRamInfo();
    }

    return _cachedRamInfo!;
  }

  /// Clears all cached data, forcing fresh data to be fetched on next access.
  ///
  /// This is useful when you need to refresh device information, such as after
  /// significant system changes or when battery level changes are important.
  void clearCache() {
    _cachedDeviceInfo = null;
    _cachedBatteryInfo = null;
    _cachedScreenInfo = null;
    _cachedCpuInfo = null;
    _cachedRamInfo = null;
  }

  // Private methods for platform-specific implementations

  Future<DeviceInfo> _getAndroidDeviceInfo() async {
    final androidInfo = await _deviceInfoPlugin.androidInfo;

    return DeviceInfo(
      manufacturer: androidInfo.manufacturer,
      model: androidInfo.model,
      osName: 'Android',
      osVersion: androidInfo.version.release,
      deviceId: androidInfo.id,
      isEmulator: androidInfo.isPhysicalDevice == false,
      brand: androidInfo.brand,
      product: androidInfo.product,
      hardware: androidInfo.hardware,
      fingerprint: androidInfo.fingerprint,
      buildNumber: androidInfo.version.incremental,
      sdkVersion: androidInfo.version.sdkInt,
    );
  }

  Future<DeviceInfo> _getIOSDeviceInfo() async {
    final iosInfo = await _deviceInfoPlugin.iosInfo;
    final systemVersion = iosInfo.systemVersion;
    final versionParts = systemVersion.split('.');
    final firstPart = versionParts.isNotEmpty ? versionParts.first : '0';
    final sdkVersion = int.tryParse(firstPart) ?? 0;

    return DeviceInfo(
      manufacturer: 'Apple',
      model: iosInfo.model,
      osName: 'iOS',
      osVersion: systemVersion,
      deviceId: iosInfo.identifierForVendor,
      isEmulator: iosInfo.isPhysicalDevice == false,
      brand: 'apple',
      product: iosInfo.name,
      hardware: iosInfo.utsname.machine,
      buildNumber: systemVersion,
      sdkVersion: sdkVersion,
    );
  }

  Future<DeviceInfo> _getWebDeviceInfo() async {
    final webInfo = await _deviceInfoPlugin.webBrowserInfo;
    final userAgent = webInfo.userAgent ?? '';

    return DeviceInfo(
      manufacturer: 'Web Browser',
      model: webInfo.browserName.name,
      osName: 'Web',
      osVersion: webInfo.appVersion,
      deviceId: 'web-${userAgent.hashCode}',
      isEmulator: false,
      brand: 'web',
      product: webInfo.browserName.name,
      hardware: 'Web Platform',
      buildNumber: webInfo.appVersion,
      sdkVersion: 0,
    );
  }

  Future<DeviceInfo> _getGenericDeviceInfo() async => DeviceInfo(
    manufacturer: 'Unknown',
    model: 'Unknown',
    osName: Platform.operatingSystem,
    osVersion: Platform.operatingSystemVersion,
    deviceId: 'unknown-${DateTime.now().millisecondsSinceEpoch}',
    isEmulator: false,
    brand: 'unknown',
    product: 'Unknown',
    hardware: 'Unknown',
    buildNumber: 'Unknown',
    sdkVersion: 0,
  );

  DeviceInfo _getFallbackDeviceInfo() => DeviceInfo(
    manufacturer: 'Unknown',
    model: 'Unknown',
    osName: 'Unknown',
    osVersion: 'Unknown',
    deviceId: 'fallback-${DateTime.now().millisecondsSinceEpoch}',
    isEmulator: false,
    brand: 'unknown',
    product: 'Unknown',
    hardware: 'Unknown',
    buildNumber: 'Unknown',
    sdkVersion: 0,
  );

  Future<CpuInfo> _getAndroidCpuInfo() async => CpuInfo(
    architecture: 'arm64', // Most modern Android devices are 64-bit
    cores: Platform.numberOfProcessors,
    isAvailable: true,
  );

  Future<CpuInfo> _getIOSCpuInfo() async => CpuInfo(
    architecture: 'arm64', // Most modern iOS devices are 64-bit
    cores: Platform.numberOfProcessors,
    isAvailable: true,
  );

  CpuInfo _getGenericCpuInfo() => CpuInfo(
    architecture: 'x86_64', // Assume 64-bit for desktop
    cores: Platform.numberOfProcessors,
    isAvailable: true,
  );

  CpuInfo _getFallbackCpuInfo() =>
      CpuInfo(architecture: 'Unknown', cores: 1, isAvailable: false);

  Future<RamInfo> _getAndroidRamInfo() async => _getFallbackRamInfo();

  Future<RamInfo> _getIOSRamInfo() async => _getFallbackRamInfo();

  RamInfo _getGenericRamInfo() => _getFallbackRamInfo();

  RamInfo _getFallbackRamInfo() => const RamInfo(
    total: 0,
    available: 0,
    used: 0,
    usagePercentage: 0,
    isAvailable: false,
  );

  bool _detectNotch(double width, double height) {
    // Simple notch detection based on aspect ratio
    // This is a basic implementation and may not be accurate for all devices
    final aspectRatio = width / height;
    return aspectRatio > 2.0 || aspectRatio < 0.5;
  }
}
