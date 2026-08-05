/// Model class containing CPU information.
class CpuInfo {
  /// CPU architecture (e.g., "arm64", "x86_64")
  final String architecture;

  /// Number of CPU cores
  final int cores;

  /// CPU frequency in Hz (if available)
  final double? frequency;

  /// CPU model name (if available)
  final String? model;

  /// CPU vendor/manufacturer (if available)
  final String? vendor;

  /// CPU usage percentage (if available)
  final double? usage;

  /// CPU temperature in Celsius (if available)
  final double? temperature;

  /// Whether CPU information is available
  final bool isAvailable;

  const CpuInfo({
    required this.architecture,
    required this.cores,
    this.frequency,
    this.model,
    this.vendor,
    this.usage,
    this.temperature,
    required this.isAvailable,
  });

  /// Creates a CpuInfo instance from a JSON map
  factory CpuInfo.fromJson(Map<String, dynamic> json) => CpuInfo(
    architecture: json['architecture'] ?? 'Unknown',
    cores: json['cores'] ?? 1,
    frequency: json['frequency'] != null
        ? (json['frequency'] as num).toDouble()
        : null,
    model: json['model'] as String?,
    vendor: json['vendor'] as String?,
    usage: json['usage'] != null ? (json['usage'] as num).toDouble() : null,
    temperature: json['temperature'] != null
        ? (json['temperature'] as num).toDouble()
        : null,
    isAvailable: json['isAvailable'] ?? false,
  );

  /// Converts the CpuInfo instance to a JSON map
  Map<String, dynamic> toJson() => {
    'architecture': architecture,
    'cores': cores,
    'frequency': frequency,
    'model': model,
    'vendor': vendor,
    'usage': usage,
    'temperature': temperature,
    'isAvailable': isAvailable,
  };

  /// Returns CPU frequency as formatted string (e.g., "2.4 GHz")
  String? get frequencyFormatted {
    if (frequency == null) return null;
    if (frequency! >= 1e9) {
      return '${(frequency! / 1e9).toStringAsFixed(1)} GHz';
    } else if (frequency! >= 1e6) {
      return '${(frequency! / 1e6).toStringAsFixed(1)} MHz';
    } else if (frequency! >= 1e3) {
      return '${(frequency! / 1e3).toStringAsFixed(1)} KHz';
    } else {
      return '${frequency!.toStringAsFixed(0)} Hz';
    }
  }

  /// Returns CPU usage as percentage string (e.g., "45%")
  String? get usagePercentage {
    if (usage == null) return null;
    return '${(usage! * 100).round()}%';
  }

  @override
  String toString() =>
      'CpuInfo(architecture: $architecture, cores: $cores, isAvailable: $isAvailable)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CpuInfo &&
        other.architecture == architecture &&
        other.cores == cores &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode =>
      architecture.hashCode ^ cores.hashCode ^ isAvailable.hashCode;
}
