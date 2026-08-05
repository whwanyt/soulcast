import 'package:dio/dio.dart';
import '../network_config.dart';

/// 认证拦截器
/// 自动为需要认证的请求添加认证信息，处理token刷新等逻辑
class AuthInterceptor extends Interceptor {
  /// 网络配置
  final NetworkConfig _config;

  /// 是否正在刷新token
  bool _isRefreshing = false;

  /// 等待刷新的请求队列
  final List<_PendingRequest> _pendingRequests = [];

  /// 构造函数
  /// [config] 网络配置
  AuthInterceptor(this._config);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 检查是否需要添加token
    final requiresAuth = _shouldAddToken(options);

    if (requiresAuth && _config.tokenProvider != null) {
      try {
        final token = await _config.tokenProvider!();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        // Token获取失败，继续请求但不添加token
      }
    }

    // 添加其他通用头信息
    options.headers['X-Requested-With'] = 'XMLHttpRequest';
    options.headers['Accept-Language'] = 'zh-CN,zh;q=0.9,en;q=0.8';

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 处理401未授权错误
    if (err.response?.statusCode == 401 &&
        _shouldHandleTokenRefresh(err.requestOptions)) {
      // 如果正在刷新token，将请求加入队列
      if (_isRefreshing) {
        final completer = _PendingRequest(err.requestOptions, handler);
        _pendingRequests.add(completer);
        return;
      }

      // 尝试刷新token
      if (_config.tokenRefresher != null && _config.tokenProvider != null) {
        _isRefreshing = true;

        try {
          // 获取当前刷新token
          final currentToken = await _config.tokenProvider!();
          if (currentToken != null && currentToken.isNotEmpty) {
            final newTokens = await _config.tokenRefresher!(currentToken);
            if (newTokens != null && newTokens['access_token'] != null) {
              // Token刷新成功，重试原始请求
              final retryResponse = await _retryRequest(
                err.requestOptions,
                newTokens['access_token']!,
              );
              handler.resolve(retryResponse);

              // 处理队列中的请求
              await _processPendingRequests(newTokens['access_token']!);
              return;
            }
          }
        } catch (e) {
          // Token刷新失败
        } finally {
          _isRefreshing = false;
          _clearPendingRequests();
        }

        // Token刷新失败，通知应用层
        _config.onTokenExpired?.call();
      }
    }

    super.onError(err, handler);
  }

  /// 判断是否应该添加token
  /// [options] 请求选项
  bool _shouldAddToken(RequestOptions options) {
    // 检查请求头中是否明确指定不需要认证
    final noAuth = options.headers['X-No-Auth'];
    if (noAuth == true || noAuth == 'true') {
      options.headers.remove('X-No-Auth');
      return false;
    }

    // 检查是否明确指定需要认证
    final requiresAuth = options.headers['X-Requires-Auth'];
    if (requiresAuth == true || requiresAuth == 'true') {
      options.headers.remove('X-Requires-Auth');
      return true;
    }

    // 默认情况下，除了登录、注册等接口，其他接口都需要认证
    final path = options.path.toLowerCase();
    final publicPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      '/public',
    ];

    return !publicPaths.any((publicPath) => path.startsWith(publicPath));
  }

  /// 判断是否应该处理token刷新
  /// [options] 请求选项
  bool _shouldHandleTokenRefresh(RequestOptions options) {
    // 刷新token的接口本身不应该触发token刷新
    final path = options.path.toLowerCase();
    return !path.startsWith('/auth/refresh');
  }

  /// 重试请求
  /// [requestOptions] 原始请求选项
  /// [newToken] 新的访问令牌
  Future<Response> _retryRequest(
    RequestOptions requestOptions,
    String newToken,
  ) async {
    // 更新请求头中的token
    requestOptions.headers['Authorization'] = 'Bearer $newToken';

    final dio = Dio();
    return await dio.fetch(requestOptions);
  }

  /// 处理队列中的待处理请求
  /// [newToken] 新的访问令牌
  Future<void> _processPendingRequests(String newToken) async {
    final requests = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final request in requests) {
      try {
        final response = await _retryRequest(request.requestOptions, newToken);
        request.handler.resolve(response);
      } catch (e) {
        request.handler.reject(
          DioException(requestOptions: request.requestOptions, error: e),
        );
      }
    }
  }

  /// 清除待处理请求队列
  void _clearPendingRequests() {
    for (final request in _pendingRequests) {
      request.handler.reject(
        DioException(
          requestOptions: request.requestOptions,
          error: 'Token refresh failed',
        ),
      );
    }
    _pendingRequests.clear();
  }
}

/// 待处理请求
class _PendingRequest {
  /// 请求选项
  final RequestOptions requestOptions;

  /// 错误处理器
  final ErrorInterceptorHandler handler;

  /// 构造函数
  /// [requestOptions] 请求选项
  /// [handler] 错误处理器
  _PendingRequest(this.requestOptions, this.handler);
}
