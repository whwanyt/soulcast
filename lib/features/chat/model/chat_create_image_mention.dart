import 'package:soulcast/i18n/strings.g.dart';

/// 聊天输入中的「创建图片」提及关键字（与 UI 高亮 / 发送路由共用）。
///
/// 路由关键字为 `@` + [Translations.main.input.createImagePlugin]，随语言变化。
abstract final class ChatCreateImageMention {
  static String keywordOf(Translations translations) =>
      '@${translations.main.input.createImagePlugin}';

  /// 当前语言环境下的路由关键字（插入输入框时使用）。
  static String get keyword => keywordOf(t);

  /// 所有可解析语言的关键字，用于检测 / strip / 高亮（含跨语言历史消息）。
  static List<String> get knownKeywords {
    final keywords = <String>{keyword};
    for (final locale in AppLocale.values) {
      try {
        keywords.add(keywordOf(locale.buildSync()));
      } on Object {
        // deferred locale 尚未加载时跳过。
      }
    }
    final list = keywords.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    return list;
  }

  static RegExp get pattern =>
      RegExp(knownKeywords.map(RegExp.escape).join('|'));

  static bool contains(String text) => knownKeywords.any(text.contains);

  /// 去掉所有语言形态的提及关键字后 trim，供 Images API prompt 使用。
  static String strip(String text) {
    var result = text;
    for (final keyword in knownKeywords) {
      result = result.replaceAll(keyword, '');
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
