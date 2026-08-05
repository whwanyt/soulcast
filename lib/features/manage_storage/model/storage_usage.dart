import 'storage_category.dart';

/// 单个分类的占用信息。
class StorageCategoryUsage {
  const StorageCategoryUsage({
    required this.category,
    required this.bytes,
    required this.itemCount,
  });

  final StorageCategory category;
  final int bytes;
  final int itemCount;

  bool get isEmpty => bytes <= 0 && itemCount <= 0;
}

/// 本地存储汇总。
class StorageUsageSnapshot {
  const StorageUsageSnapshot({
    required this.categories,
    required this.scannedAt,
  });

  final List<StorageCategoryUsage> categories;
  final DateTime scannedAt;

  int get totalBytes =>
      categories.fold<int>(0, (sum, item) => sum + item.bytes);

  StorageCategoryUsage usageOf(StorageCategory category) {
    return categories.firstWhere(
      (item) => item.category == category,
      orElse: () =>
          StorageCategoryUsage(category: category, bytes: 0, itemCount: 0),
    );
  }

  List<StorageCategoryUsage> get nonEmptyCategories {
    return categories.where((item) => item.bytes > 0).toList(growable: false);
  }
}
