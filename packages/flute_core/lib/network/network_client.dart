import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'network_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'models/api_response.dart';
import 'models/response_parser.dart';
import 'exceptions/network_exception.dart';

/// 请求选项扩展
extension RequestOptionsExtension on RequestOptions {
  /// 设置不需要认证
  RequestOptions withoutAuth() {
    headers['X-No-Auth'] = true;
    return this;
  }

  /// 设置需要认证
  RequestOptions withAuth() {
    headers['X-Requires-Auth'] = true;
    return this;
  }
}

/// 网络请求客户端
/// 提供统一的网络请求接口，支持GET、POST、PUT、DELETE等HTTP方法
/// 集成了认证、日志、错误处理等拦截器
/// 支持多实例和动态响应解析器
class NetworkClient {
  /// Dio实例
  late final Dio _dio;

  /// 网络配置
  final NetworkConfig _config;

  /// 构造函数
  /// [config] 网络配置
  NetworkClient(this._config) {
    _initDio();
  }

  /// 初始化Dio配置
  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: Duration(milliseconds: _config.connectTimeout),
        receiveTimeout: Duration(milliseconds: _config.receiveTimeout),
        sendTimeout: Duration(milliseconds: _config.sendTimeout),
        headers: _config.defaultHeaders,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    _setupInterceptors();
  }

  /// 设置拦截器
  void _setupInterceptors() {
    // 认证拦截器
    _dio.interceptors.add(AuthInterceptor(_config));

    // 日志拦截器（仅在调试模式下启用）
    if (kDebugMode && _config.enableLogging) {
      _dio.interceptors.add(LoggingInterceptor());
    }

    // 错误处理拦截器
    _dio.interceptors.add(const ErrorInterceptor());
  }

  /// GET请求
  /// [path] 请求路径
  /// [queryParameters] 查询参数
  /// [requiresAuth] 是否需要认证，null表示自动判断
  /// [cancelToken] 取消令牌
  /// [options] 请求选项
  /// [responseParser] 自定义响应解析器，如果为null则使用配置中的默认解析器
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool? requiresAuth,
    CancelToken? cancelToken,
    Options? options,
    ResponseParser<T>? responseParser,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
      return _parseResponse<T>(response, responseParser);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException.unknown(e.toString());
    }
  }

  /// POST请求
  /// [path] 请求路径
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  /// [requiresAuth] 是否需要认证，null表示自动判断
  /// [cancelToken] 取消令牌
  /// [options] 请求选项
  /// [responseParser] 自定义响应解析器，如果为null则使用配置中的默认解析器
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool? requiresAuth,
    CancelToken? cancelToken,
    Options? options,
    ResponseParser<T>? responseParser,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
      return _parseResponse<T>(response, responseParser);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException.unknown(e.toString());
    }
  }

  /// PUT请求
  /// [path] 请求路径
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  /// [requiresAuth] 是否需要认证，null表示自动判断
  /// [cancelToken] 取消令牌
  /// [options] 请求选项
  /// [responseParser] 自定义响应解析器，如果为null则使用配置中的默认解析器
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool? requiresAuth,
    CancelToken? cancelToken,
    Options? options,
    ResponseParser<T>? responseParser,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
      return _parseResponse<T>(response, responseParser);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException.unknown(e.toString());
    }
  }

  /// DELETE请求
  /// [path] 请求路径
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  /// [requiresAuth] 是否需要认证，null表示自动判断
  /// [cancelToken] 取消令牌
  /// [options] 请求选项
  /// [responseParser] 自定义响应解析器，如果为null则使用配置中的默认解析器
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool? requiresAuth,
    CancelToken? cancelToken,
    Options? options,
    ResponseParser<T>? responseParser,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
      return _parseResponse<T>(response, responseParser);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException.unknown(e.toString());
    }
  }

  /// 文件上传
  /// [path] 请求路径
  /// [formData] 表单数据
  /// [requiresAuth] 是否需要认证，null表示自动判断
  /// [cancelToken] 取消令牌
  /// [options] 请求选项
  /// [onSendProgress] 上传进度回调
  /// [responseParser] 自定义响应解析器，如果为null则使用配置中的默认解析器
  Future<ApiResponse<T>> upload<T>(
    String path,
    FormData formData, {
    bool? requiresAuth,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ResponseParser<T>? responseParser,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.post(
        path,
        data: formData,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return _parseResponse<T>(response, responseParser);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException.unknown(e.toString());
    }
  }

  /// 文件下载
  /// [urlPath] 下载URL
  /// [savePath] 保存路径
  /// [requiresAuth] 是否需要认证，null表示自动判断
  /// [cancelToken] 取消令牌
  /// [options] 请求选项
  /// [onReceiveProgress] 下载进度回调
  Future<void> download(
    String urlPath,
    String savePath, {
    bool? requiresAuth,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      await _dio.download(
        urlPath,
        savePath,
        options: requestOptions,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException.unknown(e.toString());
    }
  }

  /// 解析响应数据
  /// [response] Dio响应对象
  /// [responseParser] 自定义响应解析器
  ApiResponse<T> _parseResponse<T>(
    Response response,
    ResponseParser<T>? responseParser,
  ) {
    // 优先使用传入的解析器
    if (responseParser != null) {
      return responseParser.parseResponse(response);
    } else if (_config.defaultResponseParser != null) {
      final parser = _config.defaultResponseParser as ResponseParser<T>?;
      if (parser != null) {
        return parser.parseResponse(response);
      }
    }
    // 使用默认解析逻辑
    return ApiResponse<T>.fromResponse(response);
  }

  /// 构建请求选项
  /// [options] 原始选项
  /// [requiresAuth] 是否需要认证
  Options _buildOptions(Options? options, bool? requiresAuth) {
    final requestOptions = options ?? Options();

    if (requiresAuth != null) {
      if (requiresAuth) {
        requestOptions.headers?['X-Requires-Auth'] = true;
      } else {
        requestOptions.headers?['X-No-Auth'] = true;
      }
    }

    return requestOptions;
  }

  /// 创建取消令牌
  CancelToken createCancelToken() {
    return CancelToken();
  }

  /// 获取Dio实例（用于特殊需求）
  Dio get dio => _dio;

  /// 获取网络配置
  NetworkConfig get config => _config;
}
