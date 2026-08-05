import 'models/response_parser.dart';

/// Token获取回调函数类型
/// 返回当前有效的访问令牌
typedef TokenProvider = Future<String?> Function();

/// Token刷新回调函数类型
/// [refreshToken] 刷新令牌
/// 返回新的token信息，包含access_token和refresh_token
typedef TokenRefresher =
    Future<Map<String, String>?> Function(String refreshToken);

/// Token过期通知回调函数类型
/// 当token无法刷新时调用，通知应用层处理登录逻辑
typedef TokenExpiredCallback = void Function();

/// 网络配置类
/// 定义网络请求的基础配置信息，支持动态响应解析器
class NetworkConfig {
  /// 基础URL
  final String baseUrl;

  /// 连接超时时间（毫秒）
  final int connectTimeout;

  /// 接收超时时间（毫秒）
  final int receiveTimeout;

  /// 发送超时时间（毫秒）
  final int sendTimeout;

  /// 默认请求头
  final Map<String, String> defaultHeaders;

  /// 是否启用日志
  final bool enableLogging;

  /// Token获取回调
  final TokenProvider? tokenProvider;

  /// Token刷新回调
  final TokenRefresher? tokenRefresher;

  /// Token过期通知回调
  final TokenExpiredCallback? onTokenExpired;

  /// 默认响应解析器
  final ResponseParser<dynamic>? defaultResponseParser;

  /// 构造函数
  /// [baseUrl] 基础URL
  /// [connectTimeout] 连接超时时间，默认15秒
  /// [receiveTimeout] 接收超时时间，默认15秒
  /// [sendTimeout] 发送超时时间，默认15秒
  /// [defaultHeaders] 默认请求头
  /// [enableLogging] 是否启用日志，默认false
  /// [tokenProvider] Token获取回调
  /// [tokenRefresher] Token刷新回调
  /// [onTokenExpired] Token过期通知回调
  /// [defaultResponseParser] 默认响应解析器
  const NetworkConfig({
    required this.baseUrl,
    this.connectTimeout = 15000,
    this.receiveTimeout = 15000,
    this.sendTimeout = 15000,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.enableLogging = false,
    this.tokenProvider,
    this.tokenRefresher,
    this.onTokenExpired,
    this.defaultResponseParser,
  });

  /// 复制并修改配置
  /// [baseUrl] 新的基础URL
  /// [connectTimeout] 新的连接超时时间
  /// [receiveTimeout] 新的接收超时时间
  /// [sendTimeout] 新的发送超时时间
  /// [defaultHeaders] 新的默认请求头
  /// [enableLogging] 新的日志启用状态
  /// [tokenProvider] 新的Token获取回调
  /// [tokenRefresher] 新的Token刷新回调
  /// [onTokenExpired] 新的Token过期通知回调
  /// [defaultResponseParser] 新的默认响应解析器
  NetworkConfig copyWith({
    String? baseUrl,
    int? connectTimeout,
    int? receiveTimeout,
    int? sendTimeout,
    Map<String, String>? defaultHeaders,
    bool? enableLogging,
    TokenProvider? tokenProvider,
    TokenRefresher? tokenRefresher,
    TokenExpiredCallback? onTokenExpired,
    ResponseParser<dynamic>? defaultResponseParser,
  }) {
    return NetworkConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      enableLogging: enableLogging ?? this.enableLogging,
      tokenProvider: tokenProvider ?? this.tokenProvider,
      tokenRefresher: tokenRefresher ?? this.tokenRefresher,
      onTokenExpired: onTokenExpired ?? this.onTokenExpired,
      defaultResponseParser:
          defaultResponseParser ?? this.defaultResponseParser,
    );
  }
}
