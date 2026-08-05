import 'dart:convert';

import 'package:flute_core/app/repository.dart';
import 'package:flute_core/device_info/device_info.dart';
import 'package:flute_core/log/log.dart';
import 'package:flute_core/storage/storage.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/repository/app_preferences_repository.dart';
import 'package:soulcast/shared/storage/app_directories.dart';
import 'package:soulcast/shared/storage/isar_database.dart';
import 'package:soulcast/shared/syntax_highlight/syntax_highlighter_service.dart';
import 'package:soulcast/shared/theme/app_boot_appearance.dart';

import 'data/app_state.dart';

/// 应用启动仓库实现类
class AppStartRepo implements AppStartRepository<AppState> {
  const AppStartRepo();

  @override
  Future<AppState> initApp() async {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await Storage.init();

    /// 可以在这里进行数据库初始化、网络配置等操作
    final appDirectories = await AppDirectories.resolve();
    await Log.init(
      LogConfig(
        enableFileLog: true,
        logLevel: LogLevel.all,
        recordLevel: LogLevel.info,
        logDirectory: appDirectories.logs,
      ),
    );
    Log.i("开始服务初始化", tag: "START");
    final savedLocale = await _restoreStoredLocale();
    await LocaleSettings.setLocale(savedLocale);
    initNetwork();
    await SyntaxHighlighterService.initialize();
    final deviceInfo = await SmartDeviceInfo.instance.init();
    Log.i("设备信息: ${jsonEncode(deviceInfo.toJson())}", tag: "START");
    Log.i("服务初始化完成", tag: "START");

    /// 返回初始化的应用状态
    return const AppState(0);
  }

  @override
  Future<void> fixError(Object error, {Object? extra}) async {
    /// 模拟错误修复过程
    // await Future.delayed(const Duration(seconds: 1));

    /// 可以在这里处理具体的错误修复逻辑
  }

  /// 初始化网络客户端
  void initNetwork() {}

  Future<AppLocale> _restoreStoredLocale() async {
    final savedThemeModeName = await Storage.getString(
      appPreferencesThemeModeKey,
    );
    final savedLocaleName = await Storage.getString(appPreferencesLocaleKey);
    final isar = await openAppIsar();
    final repository = AppPreferencesRepository(isar);
    final preferences = repository.ensurePreferences(
      themeModeName: savedThemeModeName ?? AppThemeModePreference.system.name,
      localeName: savedLocaleName ?? AppLocaleUtils.findDeviceLocale().name,
      responseModeName: ChatResponseModePreference.stream.name,
    );
    final themeMode = AppThemeModePreference.values.firstWhere(
      (mode) => mode.name == preferences.themeModeName,
      orElse: () => AppThemeModePreference.system,
    );
    // Same timing as LocaleSettings.setLocale: apply before initApp returns
    // so Splash can rebuild dark while remaining startup work continues.
    AppBootAppearance.setThemeMode(themeMode.themeMode);
    // Keep the native splash until themeMode has been applied to MaterialApp.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    await Storage.setString(appPreferencesThemeModeKey, themeMode.name);
    return AppLocale.values.firstWhere(
      (locale) => locale.name == preferences.localeName,
      orElse: () => AppLocaleUtils.findDeviceLocale(),
    );
  }
}
