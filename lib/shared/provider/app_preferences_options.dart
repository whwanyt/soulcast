part of 'app_preferences_provider.dart';

/// 用户可选的应用主题模式。
enum AppThemeModePreference {
  system(icon: Icons.brightness_auto_outlined, themeMode: ThemeMode.system),
  light(icon: Icons.light_mode_outlined, themeMode: ThemeMode.light),
  dark(icon: Icons.dark_mode_outlined, themeMode: ThemeMode.dark);

  const AppThemeModePreference({required this.icon, required this.themeMode});

  final IconData icon;
  final ThemeMode themeMode;

  String label(Translations translations) {
    return switch (this) {
      AppThemeModePreference.system => translations.settings.themeSystem,
      AppThemeModePreference.light => translations.settings.themeLight,
      AppThemeModePreference.dark => translations.settings.themeDark,
    };
  }
}

/// 聊天回复的传输与展示模式。
enum ChatResponseModePreference { normal, stream }

/// 为回复模式提供设置页所需的图标与本地化名称。
extension ChatResponseModePreferenceLabel on ChatResponseModePreference {
  IconData get icon {
    return switch (this) {
      ChatResponseModePreference.normal => Icons.chat_bubble_outline_rounded,
      ChatResponseModePreference.stream => Icons.bolt_rounded,
    };
  }

  String label(Translations translations) {
    return switch (this) {
      ChatResponseModePreference.normal => translations.settings.responseNormal,
      ChatResponseModePreference.stream => translations.settings.responseStream,
    };
  }
}

/// 设置页可选择的应用语言。
class AppLanguageOption {
  const AppLanguageOption({required this.locale, required this.nativeName});

  final AppLocale locale;
  final String nativeName;

  String localizedName(Translations translations) {
    return switch (locale) {
      AppLocale.zhCn => translations.localeName.zhCn,
      AppLocale.en => translations.localeName.en,
    };
  }
}

const appLanguageOptions = [
  AppLanguageOption(locale: AppLocale.zhCn, nativeName: '简体中文'),
  AppLanguageOption(locale: AppLocale.en, nativeName: 'English'),
];
