import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_start_notifier.dart';
import 'app_start_state.dart';
import 'repository.dart';
import 'action/app_start_action.dart';

/// 应用启动配置类
class AppStartConfig<S> {
  final AppStartRepository<S> repository;
  final AppStartAction<S> startAction;
  final int minStartDurationMs;

  const AppStartConfig({
    required this.repository,
    required this.startAction,
    this.minStartDurationMs = 600,
  });
}

/// 应用启动配置Provider
/// 需要在应用启动时通过 ProviderScope.overrides 进行覆盖
final appStartConfigProvider = Provider<AppStartConfig>((ref) {
  throw UnimplementedError(
    'AppStartConfig must be overridden in ProviderScope',
  );
});

/// 应用启动状态Provider
final appStartStateProvider = NotifierProvider<AppStartNotifier, AppStartState>(
  () => AppStartNotifier(),
);
