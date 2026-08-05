/// Model class containing device information.
class DeviceInfo {
  /// Device manufacturer (e.g., "Samsung", "Apple")
  final String? manufacturer;

  /// Device model name (e.g., "Galaxy S21", "iPhone 14")
  final String? model;

  /// Operating system name (e.g., "Android", "iOS")
  final String? osName;

  /// Operating system version (e.g., "13.0", "16.5")
  final String? osVersion;

  /// Unique device identifier
  final String? deviceId;

  /// Whether running on emulator/simulator
  final bool isEmulator;

  /// Device brand (e.g., "samsung", "apple")
  final String? brand;

  /// Device product name
  final String? product;

  /// Device hardware name
  final String? hardware;

  /// Device fingerprint (Android only)
  final String? fingerprint;

  /// Device serial number (if available)
  final String? serialNumber;

  /// Device build number
  final String? buildNumber;

  /// SDK version (Android) or iOS version
  final int sdkVersion;

  const DeviceInfo({
    this.manufacturer,
    this.model,
    this.osName,
    this.osVersion,
    this.deviceId,
    required this.isEmulator,
    this.brand,
    this.product,
    this.hardware,
    this.fingerprint,
    this.serialNumber,
    this.buildNumber,
    required this.sdkVersion,
  });

  /// Creates a DeviceInfo instance from a JSON map
  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    manufacturer: json['manufacturer'] as String?,
    model: json['model'] as String?,
    osName: json['osName'] as String?,
    osVersion: json['osVersion'] as String?,
    deviceId: json['deviceId'] as String?,
    isEmulator: json['isEmulator'] ?? false,
    brand: json['brand'] as String?,
    product: json['product'] as String?,
    hardware: json['hardware'] as String?,
    fingerprint: json['fingerprint'] as String?,
    serialNumber: json['serialNumber'] as String?,
    buildNumber: json['buildNumber'] as String?,
    sdkVersion: json['sdkVersion'] ?? 0,
  );

  /// Converts the DeviceInfo instance to a JSON map
  Map<String, dynamic> toJson() => {
    'manufacturer': manufacturer,
    'model': model,
    'osName': osName,
    'osVersion': osVersion,
    'deviceId': deviceId,
    'isEmulator': isEmulator,
    'brand': brand,
    'product': product,
    'hardware': hardware,
    'fingerprint': fingerprint,
    'serialNumber': serialNumber,
    'buildNumber': buildNumber,
    'sdkVersion': sdkVersion,
  };

  @override
  String toString() =>
      'DeviceInfo(manufacturer: $manufacturer, model: $model, osName: $osName, osVersion: $osVersion, isEmulator: $isEmulator)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo &&
        other.manufacturer == manufacturer &&
        other.model == model &&
        other.osName == osName &&
        other.osVersion == osVersion &&
        other.deviceId == deviceId &&
        other.isEmulator == isEmulator;
  }

  @override
  int get hashCode =>
      manufacturer.hashCode ^
      model.hashCode ^
      osName.hashCode ^
      osVersion.hashCode ^
      deviceId.hashCode ^
      isEmulator.hashCode;
}
