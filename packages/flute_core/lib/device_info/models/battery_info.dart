/// Model class containing battery information.
class BatteryInfo {
  /// Battery level (0.0 to 1.0)
  final double level;

  /// Whether the device is charging
  final bool isCharging;

  /// Battery health status (if available)
  final String? health;

  /// Battery temperature in Celsius (if available)
  final double? temperature;

  /// Battery voltage in millivolts (if available)
  final int? voltage;

  /// Whether battery information is available
  final bool isAvailable;

  const BatteryInfo({
    required this.level,
    required this.isCharging,
    this.health,
    this.temperature,
    this.voltage,
    required this.isAvailable,
  });

  /// Creates a BatteryInfo instance from a JSON map
  factory BatteryInfo.fromJson(Map<String, dynamic> json) => BatteryInfo(
    level: (json['level'] as num?)?.toDouble() ?? 0.0,
    isCharging: json['isCharging'] ?? false,
    health: json['health'] as String?,
    temperature: json['temperature'] != null
        ? (json['temperature'] as num).toDouble()
        : null,
    voltage: json['voltage'] as int?,
    isAvailable: json['isAvailable'] ?? false,
  );

  /// Converts the BatteryInfo instance to a JSON map
  Map<String, dynamic> toJson() => {
    'level': level,
    'isCharging': isCharging,
    'health': health,
    'temperature': temperature,
    'voltage': voltage,
    'isAvailable': isAvailable,
  };

  /// Returns battery level as percentage string (e.g., "85%")
  String get levelPercentage => '${(level * 100).round()}%';

  @override
  String toString() =>
      'BatteryInfo(level: $levelPercentage, isCharging: $isCharging, isAvailable: $isAvailable)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatteryInfo &&
        other.level == level &&
        other.isCharging == isCharging &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode =>
      level.hashCode ^ isCharging.hashCode ^ isAvailable.hashCode;
}
