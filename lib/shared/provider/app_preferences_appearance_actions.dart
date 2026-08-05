part of 'app_preferences_provider.dart';

mixin _AppPreferencesAppearanceActions on _AppPreferencesController {
  Future<void> selectThemeMode(AppThemeModePreference themeMode) async {
    if (state.themeMode == themeMode) {
      return;
    }

    state = state.copyWith(themeMode: themeMode);
    AppBootAppearance.setThemeMode(themeMode.themeMode);
    final repository = await _repository();
    repository.saveThemeMode(themeMode.name);
    await Storage.setString(appPreferencesThemeModeKey, themeMode.name);
  }

  Future<void> selectLocale(AppLocale locale) async {
    if (state.locale == locale) {
      return;
    }

    state = state.copyWith(locale: locale);
    await LocaleSettings.setLocale(locale);
    final repository = await _repository();
    repository.saveLocale(locale.name);
  }

  Future<void> selectResponseMode(
    ChatResponseModePreference responseMode,
  ) async {
    if (state.responseMode == responseMode) {
      return;
    }

    state = state.copyWith(responseMode: responseMode);
    final repository = await _repository();
    repository.saveResponseMode(responseMode.name);
  }

  /// 保存或清除指定提示词的自定义模板；[value] 为空表示恢复默认。
}
