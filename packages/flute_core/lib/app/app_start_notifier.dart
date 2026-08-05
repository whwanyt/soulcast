import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_start_state.dart';
import 'providers.dart';

/// 应用启动状态管理器
class AppStartNotifier<S> extends Notifier<AppStartState<S>> {
  int _timeRecord = 0;

  /// 获取应用启动配置
  AppStartConfig<S> get config =>
      ref.read(appStartConfigProvider) as AppStartConfig<S>;

  @override
  AppStartState<S> build() {
    // 在 build 方法中初始化状态并启动应用
    startApp();
    return const AppStarting();
  }

  /// 开始应用启动流程
  Future<void> startApp() async {
    _timeRecord = DateTime.now().millisecondsSinceEpoch;
    state = const AppStarting();

    S data;
    try {
      // 处理初始化异步任务
      data = await config.repository.initApp();
    } catch (e, s) {
      state = AppStartFailed(e, s, FixType.none);
      return;
    }

    // 计算初始化耗时
    int cost = DateTime.now().millisecondsSinceEpoch - _timeRecord;
    int waitTime = config.minStartDurationMs - cost;

    if (waitTime > 0) {
      // 启动时间小于最小时长，等待时间差
      state = AppLoadDone(cost, data);
      await Future.delayed(Duration(milliseconds: waitTime));
    } else {
      // 启动时间超过最小时长，给一点预加载时间
      state = AppLoadDone(cost, data);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    state = AppStartSuccess(data);
  }

  /// 修复启动错误
  Future<void> fixError() async {
    if (state is AppStartFailed<S>) {
      final failedState = state as AppStartFailed<S>;
      state = AppStartFailed(
        failedState.error,
        failedState.trace,
        FixType.fixing,
      );

      try {
        await config.repository.fixError(failedState.error);
        state = AppStartFailed(
          failedState.error,
          failedState.trace,
          FixType.fixed,
        );
        // 重新启动应用
        await startApp();
      } catch (e, s) {
        state = AppStartFailed(e, s, FixType.fixError);
      }
    }
  }
}
