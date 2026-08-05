import 'package:flutter/material.dart';
import 'package:soulcast/features/manage_storage/manage_storage.dart';

/// 存储分类在页面内共用的视觉映射。
abstract final class StorageCategoryStyle {
  /// 返回分类在占用条和图例中使用的固定颜色。
  static Color chartColor(StorageCategory category) {
    return switch (category) {
      StorageCategory.images => const Color(0xFF5B8FF9),
      StorageCategory.files => const Color(0xFF5AD8A6),
      StorageCategory.chatHistory => const Color(0xFF34C759),
      StorageCategory.assistant => const Color(0xFFF6BD16),
      StorageCategory.cache => const Color(0xFFE86452),
      StorageCategory.logs => const Color(0xFF6F5EF9),
      StorageCategory.models => const Color(0xFF13C2C2),
    };
  }

  /// 返回分类列表与详情卡片使用的语义图标。
  static IconData icon(StorageCategory category) {
    return switch (category) {
      StorageCategory.images => Icons.image_outlined,
      StorageCategory.files => Icons.insert_drive_file_outlined,
      StorageCategory.chatHistory => Icons.chat_bubble_outline,
      StorageCategory.assistant => Icons.smart_toy_outlined,
      StorageCategory.cache => Icons.cached_outlined,
      StorageCategory.logs => Icons.description_outlined,
      StorageCategory.models => Icons.graphic_eq_outlined,
    };
  }
}
