import 'dart:math';

/// Model class containing RAM (memory) information.
class RamInfo {
  /// Total RAM in bytes
  final int total;

  /// Available RAM in bytes
  final int available;

  /// Used RAM in bytes
  final int used;

  /// RAM usage percentage (0.0 to 1.0)
  final double usagePercentage;

  /// Whether RAM information is available
  final bool isAvailable;

  const RamInfo({
    required this.total,
    required this.available,
    required this.used,
    required this.usagePercentage,
    required this.isAvailable,
  });

  /// Creates a RamInfo instance from a JSON map
  factory RamInfo.fromJson(Map<String, dynamic> json) => RamInfo(
    total: json['total'] ?? 0,
    available: json['available'] ?? 0,
    used: json['used'] ?? 0,
    usagePercentage: (json['usagePercentage'] as num?)?.toDouble() ?? 0.0,
    isAvailable: json['isAvailable'] ?? false,
  );

  /// Converts the RamInfo instance to a JSON map
  Map<String, dynamic> toJson() => {
    'total': total,
    'available': available,
    'used': used,
    'usagePercentage': usagePercentage,
    'isAvailable': isAvailable,
  };

  /// Returns total RAM as formatted string (e.g., "8.0 GB")
  String get totalFormatted => _formatBytes(total);

  /// Returns available RAM as formatted string (e.g., "3.2 GB")
  String get availableFormatted => _formatBytes(available);

  /// Returns used RAM as formatted string (e.g., "4.8 GB")
  String get usedFormatted => _formatBytes(used);

  /// Returns RAM usage as percentage string (e.g., "60%")
  String get usagePercentageFormatted => '${(usagePercentage * 100).round()}%';

  /// Formats bytes into human-readable string
  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  String toString() =>
      'RamInfo(total: $totalFormatted, available: $availableFormatted, usage: $usagePercentageFormatted, isAvailable: $isAvailable)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RamInfo &&
        other.total == total &&
        other.available == available &&
        other.used == used &&
        other.usagePercentage == usagePercentage &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode =>
      total.hashCode ^
      available.hashCode ^
      used.hashCode ^
      usagePercentage.hashCode ^
      isAvailable.hashCode;
}
