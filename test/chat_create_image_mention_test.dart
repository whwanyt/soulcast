import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/features/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    await LocaleSettings.setLocale(AppLocale.en);
  });

  test('keyword follows current locale', () async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    expect(ChatCreateImageMention.keyword, '@创建图片');

    await LocaleSettings.setLocale(AppLocale.en);
    expect(ChatCreateImageMention.keyword, '@Create image');
  });

  test('contains detects create-image mention in any loaded locale', () async {
    await LocaleSettings.setLocale(AppLocale.en);
    expect(ChatCreateImageMention.contains('@Create image apple'), isTrue);
    expect(ChatCreateImageMention.contains('@创建图片 apple'), isTrue);
    expect(ChatCreateImageMention.contains('画一只猫'), isFalse);
    expect(ChatCreateImageMention.contains(''), isFalse);
  });

  test('strip removes mention keyword and collapses spaces', () async {
    await LocaleSettings.setLocale(AppLocale.en);
    expect(ChatCreateImageMention.strip('@Create image apple'), 'apple');
    expect(ChatCreateImageMention.strip('@创建图片'), '');
    expect(
      ChatCreateImageMention.strip('  @Create image   red   balloon  '),
      'red balloon',
    );
  });
}
