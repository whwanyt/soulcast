import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络连接状态枚举
enum NetworkStatus {
  /// 已连接
  connected,

  /// 已断开
  disconnected,

  /// 未知状态
  unknown,
}

/// 网络连接类型枚举
enum NetworkType {
  /// WiFi
  wifi,

  /// 移动网络
  mobile,

  /// 以太网
  ethernet,

  /// 无连接
  none,

  /// 未知类型
  unknown,
}

/// 网络连接监听器
/// 监听网络连接状态变化，提供网络状态查询功能
class NetworkConnectivity {
  /// Connectivity实例
  final Connectivity _connectivity = Connectivity();

  /// 网络状态流控制器
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  /// 网络类型流控制器
  final StreamController<NetworkType> _typeController =
      StreamController<NetworkType>.broadcast();

  /// 连接状态订阅
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// 当前网络状态
  NetworkStatus _currentStatus = NetworkStatus.unknown;

  /// 当前网络类型
  NetworkType _currentType = NetworkType.unknown;

  /// 单例实例
  static NetworkConnectivity? _instance;

  /// 私有构造函数
  NetworkConnectivity._() {
    _initialize();
  }

  /// 获取单例实例
  static NetworkConnectivity get instance {
    return _instance ??= NetworkConnectivity._();
  }

  /// 网络状态流
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// 网络类型流
  Stream<NetworkType> get typeStream => _typeController.stream;

  /// 当前网络状态
  NetworkStatus get currentStatus => _currentStatus;

  /// 当前网络类型
  NetworkType get currentType => _currentType;

  /// 是否已连接网络
  bool get isConnected => _currentStatus == NetworkStatus.connected;

  /// 是否为WiFi连接
  bool get isWiFi => _currentType == NetworkType.wifi;

  /// 是否为移动网络连接
  bool get isMobile => _currentType == NetworkType.mobile;

  /// 初始化网络监听
  void _initialize() {
    // 获取初始网络状态
    _checkInitialConnectivity();

    // 监听网络状态变化
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        _updateStatus(NetworkStatus.unknown, NetworkType.unknown);
      },
    );
  }

  /// 检查初始网络连接状态
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _onConnectivityChanged(results);
    } catch (e) {
      _updateStatus(NetworkStatus.unknown, NetworkType.unknown);
    }
  }

  /// 网络连接状态变化回调
  /// [results] 连接结果列表
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      _updateStatus(NetworkStatus.disconnected, NetworkType.none);
      return;
    }

    // 取第一个有效的连接类型
    final result = results.first;

    NetworkStatus status;
    NetworkType type;

    switch (result) {
      case ConnectivityResult.wifi:
        status = NetworkStatus.connected;
        type = NetworkType.wifi;
        break;
      case ConnectivityResult.mobile:
        status = NetworkStatus.connected;
        type = NetworkType.mobile;
        break;
      case ConnectivityResult.ethernet:
        status = NetworkStatus.connected;
        type = NetworkType.ethernet;
        break;
      case ConnectivityResult.none:
        status = NetworkStatus.disconnected;
        type = NetworkType.none;
        break;
      default:
        status = NetworkStatus.unknown;
        type = NetworkType.unknown;
        break;
    }

    _updateStatus(status, type);
  }

  /// 更新网络状态
  /// [status] 网络状态
  /// [type] 网络类型
  void _updateStatus(NetworkStatus status, NetworkType type) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
    }

    if (_currentType != type) {
      _currentType = type;
      _typeController.add(type);
    }
  }

  /// 手动检查网络连接状态
  Future<NetworkStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _onConnectivityChanged(results);
      return _currentStatus;
    } catch (e) {
      _updateStatus(NetworkStatus.unknown, NetworkType.unknown);
      return NetworkStatus.unknown;
    }
  }

  /// 释放资源
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    _typeController.close();
  }
}
