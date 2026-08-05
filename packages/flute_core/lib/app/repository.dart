/// 应用启动仓库接口
abstract class AppStartRepository<S> {
  const AppStartRepository();

  /// 初始化应用并返回应用状态
  Future<S> initApp();

  /// 修复启动错误
  Future<void> fixError(Object error, {Object? extra}) async {}
}
