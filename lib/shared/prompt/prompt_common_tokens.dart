import 'prompt_tokens.dart';

/// 通用提示词 token 的运行时快照。
///
/// 由 [AppPreferences] 在恢复/更新昵称时同步；渲染侧经
/// [assemblePromptTokenValues] 自动注入，业务调用方无需再传。
abstract final class PromptCommonTokens {
  static String _user = '';

  /// 当前用户昵称（供 `{{user}}` 替换）。
  static String get user => _user;

  /// 与偏好中的昵称对齐。
  static void sync({required String user}) {
    _user = user.trim();
  }

  /// 通用 token 取值表。
  static Map<String, Object> values() => {PromptTokenNames.user: _user};
}

/// 组装最终渲染用的 token：先注入通用变量，业务值可覆盖同名键。
Map<String, Object> assemblePromptTokenValues([
  Map<String, Object> values = const {},
]) {
  return {...PromptCommonTokens.values(), ...values};
}
