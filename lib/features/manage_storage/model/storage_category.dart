/// 本地存储分类。
enum StorageCategory {
  images,
  files,
  chatHistory,
  assistant,
  cache,
  logs,
  models;

  static StorageCategory? tryParse(String value) {
    for (final category in StorageCategory.values) {
      if (category.name == value) {
        return category;
      }
    }
    return null;
  }

  bool get canClear {
    return switch (this) {
      StorageCategory.images ||
      StorageCategory.files ||
      StorageCategory.chatHistory ||
      StorageCategory.assistant ||
      StorageCategory.cache ||
      StorageCategory.logs ||
      StorageCategory.models => true,
    };
  }
}
