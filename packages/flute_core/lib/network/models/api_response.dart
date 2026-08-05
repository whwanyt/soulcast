import 'package:dio/dio.dart';

/// API响应模型
/// 统一封装API响应数据格式
class ApiResponse<T> {
  /// 响应状态码
  final int statusCode;

  /// 响应消息
  final String message;

  /// 响应数据
  final T? data;

  /// 是否成功
  final bool success;

  /// 响应头
  final Headers? headers;

  /// 构造函数
  /// [statusCode] 状态码
  /// [message] 响应消息
  /// [data] 响应数据
  /// [success] 是否成功
  /// [headers] 响应头
  const ApiResponse({
    required this.statusCode,
    required this.message,
    this.data,
    required this.success,
    this.headers,
  });

  /// 从Dio响应创建ApiResponse
  /// [response] Dio响应对象
  factory ApiResponse.fromResponse(Response response) {
    final responseData = response.data;

    // 根据实际API格式调整解析逻辑
    if (responseData is Map<String, dynamic>) {
      return ApiResponse<T>(
        statusCode: response.statusCode ?? 200,
        message: responseData['message'] ?? 'Success',
        data: responseData['data'] as T?,
        success: responseData['success'] ?? true,
        headers: response.headers,
      );
    } else {
      return ApiResponse<T>(
        statusCode: response.statusCode ?? 200,
        message: 'Success',
        data: responseData as T?,
        success: true,
        headers: response.headers,
      );
    }
  }

  /// 创建成功响应
  /// [data] 响应数据
  /// [message] 响应消息
  /// [statusCode] 状态码
  factory ApiResponse.success({
    T? data,
    String message = 'Success',
    int statusCode = 200,
  }) {
    return ApiResponse<T>(
      statusCode: statusCode,
      message: message,
      data: data,
      success: true,
    );
  }

  /// 创建失败响应
  /// [message] 错误消息
  /// [statusCode] 状态码
  factory ApiResponse.error({required String message, int statusCode = 500}) {
    return ApiResponse<T>(
      statusCode: statusCode,
      message: message,
      data: null,
      success: false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'data': data,
      'success': success,
    };
  }

  @override
  String toString() {
    return 'ApiResponse{statusCode: $statusCode, message: $message, data: $data, success: $success}';
  }
}
