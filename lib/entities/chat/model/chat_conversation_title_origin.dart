/// 会话标题来源及后续自动改写权限。
enum ChatConversationTitleOrigin {
  /// 尚未由用户锁定，允许临时截断与 LLM 自动标题。
  pending,

  /// 已由 LLM 自动生成，不再自动改写。
  generated,

  /// 用户手动命名（或角色会话固定名），永不自动改写。
  manual,
}
