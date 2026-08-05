import 'package:flutter/material.dart';

/// 启动期外观种子，时机对齐 [LocaleSettings]：在 initApp 读到偏好后立刻写入，
/// 供根 [MaterialApp] 在 Riverpod restore 之前切换 themeMode。
class AppBootAppearance {
  AppBootAppearance._();

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.system,
  );

  static void setThemeMode(ThemeMode mode) {
    if (themeMode.value == mode) {
      return;
    }
    themeMode.value = mode;
  }
}
