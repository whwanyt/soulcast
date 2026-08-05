/// 应用启动状态定义
sealed class AppStartState<S> {
  const AppStartState();
}

/// 启动中状态
class AppStarting<S> extends AppStartState<S> {
  const AppStarting();
}

/// 加载完成状态
class AppLoadDone<S> extends AppStartState<S> {
  final int cost;
  final S data;
  const AppLoadDone(this.cost, this.data);
}

/// 启动成功状态
class AppStartSuccess<S> extends AppStartState<S> {
  final S data;
  const AppStartSuccess(this.data);
}

/// 启动失败状态
class AppStartFailed<S> extends AppStartState<S> {
  final Object error;
  final StackTrace trace;
  final FixType fix;
  const AppStartFailed(this.error, this.trace, this.fix);
}

/// 修复类型枚举
enum FixType { none, fixing, fixed, fixError }
