import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_start_notifier.dart';
import 'app_start_state.dart';
import 'providers.dart';

/// Riverpod扩展方法
extension AppStartExtension on WidgetRef {
  /// 获取当前启动状态
  AppStartState get appStartState => watch(appStartStateProvider);

  /// 获取启动状态通知器
  AppStartNotifier get appStartNotifier => read(appStartStateProvider.notifier);

  /// 重新启动应用
  Future<void> restartApp() => appStartNotifier.startApp();

  /// 修复启动错误
  Future<void> fixStartError() => appStartNotifier.fixError();
}
