import 'package:dio/dio.dart';

/// 网络异常类型枚举
enum NetworkExceptionType {
  /// 连接超时
  connectTimeout,

  /// 发送超时
  sendTimeout,

  /// 接收超时
  receiveTimeout,

  /// 请求取消
  cancel,

  /// 响应错误
  response,

  /// 其他错误
  other,

  /// 未知错误
  unknown,
}

/// 网络异常类
/// 统一处理网络请求中的各种异常情况
class NetworkException implements Exception {
  /// 异常类型
  final NetworkExceptionType type;

  /// 错误消息
  final String message;

  /// 状态码
  final int? statusCode;

  /// 原始异常
  final dynamic originalException;

  /// 构造函数
  /// [type] 异常类型
  /// [message] 错误消息
  /// [statusCode] 状态码
  /// [originalException] 原始异常
  const NetworkException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalException,
  });

  /// 从DioException创建NetworkException
  /// [dioException] Dio异常对象
  factory NetworkException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          type: NetworkExceptionType.connectTimeout,
          message: '连接超时，请检查网络连接',
          originalException: dioException,
        );
      case DioExceptionType.sendTimeout:
        return NetworkException(
          type: NetworkExceptionType.sendTimeout,
          message: '请求发送超时，请稍后重试',
          originalException: dioException,
        );
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          type: NetworkExceptionType.receiveTimeout,
          message: '响应接收超时，请稍后重试',
          originalException: dioException,
        );
      case DioExceptionType.cancel:
        return NetworkException(
          type: NetworkExceptionType.cancel,
          message: '请求已取消',
          originalException: dioException,
        );
      case DioExceptionType.badResponse:
        return NetworkException(
          type: NetworkExceptionType.response,
          message: _getResponseErrorMessage(dioException.response),
          statusCode: dioException.response?.statusCode,
          originalException: dioException,
        );
      case DioExceptionType.unknown:
      default:
        return NetworkException(
          type: NetworkExceptionType.other,
          message: '网络请求失败：${dioException.message}',
          originalException: dioException,
        );
    }
  }

  /// 创建连接超时异常
  factory NetworkException.connectTimeout() {
    return const NetworkException(
      type: NetworkExceptionType.connectTimeout,
      message: '连接超时，请检查网络连接',
    );
  }

  /// 创建请求取消异常
  factory NetworkException.requestCancelled() {
    return const NetworkException(
      type: NetworkExceptionType.cancel,
      message: '请求已取消',
    );
  }

  /// 创建未知异常
  /// [message] 错误消息
  factory NetworkException.unknown(String message) {
    return NetworkException(
      type: NetworkExceptionType.unknown,
      message: '未知错误：$message',
    );
  }

  /// 获取响应错误消息
  /// [response] 响应对象
  static String _getResponseErrorMessage(Response? response) {
    if (response == null) {
      return '服务器响应异常';
    }

    final statusCode = response.statusCode;
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请重新登录';
      case 403:
        return '禁止访问';
      case 404:
        return '请求的资源不存在';
      case 405:
        return '请求方法不允许';
      case 408:
        return '请求超时';
      case 409:
        return '请求冲突';
      case 422:
        return '请求参数验证失败';
      case 429:
        return '请求过于频繁，请稍后重试';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务不可用';
      case 504:
        return '网关超时';
      default:
        return '服务器错误（$statusCode）';
    }
  }

  @override
  String toString() {
    return 'NetworkException{type: $type, message: $message, statusCode: $statusCode}';
  }
}
