/// 定位权限引导 Port（由 widget 层提供 UI 实现）。
abstract interface class LocationPermissionDialog {
  Future<bool> showPermissionRequest();

  Future<bool> showOpenAppSettings();

  Future<bool> showServiceDisabled();
}
