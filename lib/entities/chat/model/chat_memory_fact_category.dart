/// 长期记忆事实的业务分类。
enum ChatMemoryFactCategory {
  relationship,
  worldSetting,
  plotState,
  preference,
  constraint,
  other;

  /// 从持久化名称解析分类，未知名称归入 [other]。
  static ChatMemoryFactCategory fromName(String? name) {
    return ChatMemoryFactCategory.values.firstWhere(
      (category) => category.name == name,
      orElse: () => ChatMemoryFactCategory.other,
    );
  }
}
