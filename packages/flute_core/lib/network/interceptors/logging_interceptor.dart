import 'package:dio/dio.dart';
import 'package:flute_core/log/log.dart';
import 'package:flutter/foundation.dart';

/// 日志拦截器
/// 记录网络请求和响应的详细信息，便于调试
class LoggingInterceptor extends Interceptor {
  /// 是否启用详细日志
  final bool enableDetailedLogging;

  /// 是否记录请求体
  final bool logRequestBody;

  /// 是否记录响应体
  final bool logResponseBody;

  /// 最大日志长度
  final int maxLogLength;

  /// 请求开始时间映射表
  final Map<RequestOptions, DateTime> _requestStartTimes = {};

  /// 构造函数
  /// [enableDetailedLogging] 是否启用详细日志
  /// [logRequestBody] 是否记录请求体
  /// [logResponseBody] 是否记录响应体
  /// [maxLogLength] 最大日志长度
  LoggingInterceptor({
    this.enableDetailedLogging = true,
    this.logRequestBody = true,
    this.logResponseBody = true,
    this.maxLogLength = 1000,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      // 记录请求开始时间
      _requestStartTimes[options] = DateTime.now();
      _logRequest(options);
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logResponse(response);
      // 清理请求开始时间记录
      _requestStartTimes.remove(response.requestOptions);
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logError(err);
      // 清理请求开始时间记录
      _requestStartTimes.remove(err.requestOptions);
    }
    super.onError(err, handler);
  }

  /// 记录请求信息
  /// [options] 请求选项
  void _logRequest(RequestOptions options) {
    final uri = options.uri;
    final method = options.method.toUpperCase();

    final logBuffer = StringBuffer();
    logBuffer.writeln('🚀 REQUEST');
    logBuffer.writeln('Method: $method');
    logBuffer.writeln('URL: $uri');

    if (enableDetailedLogging) {
      // 记录请求头
      if (options.headers.isNotEmpty) {
        logBuffer.writeln('Headers:');
        options.headers.forEach((key, value) {
          logBuffer.writeln('  $key: $value');
        });
      }

      // 记录查询参数
      if (options.queryParameters.isNotEmpty) {
        logBuffer.writeln('Query Parameters:');
        options.queryParameters.forEach((key, value) {
          logBuffer.writeln('  $key: $value');
        });
      }

      // 记录请求体
      if (logRequestBody && options.data != null) {
        logBuffer.writeln('Body:');
        final bodyStr = _formatData(options.data);
        logBuffer.writeln('  $bodyStr');
      }
    }

    // 一次性输出完整的日志
    Log.i(logBuffer.toString().trim(), tag: "HTTP");
  }

  /// 记录响应信息
  /// [response] 响应对象
  void _logResponse(Response response) {
    final uri = response.requestOptions.uri;
    final method = response.requestOptions.method.toUpperCase();
    final statusCode = response.statusCode;
    final duration = _calculateDuration(response.requestOptions);

    final logBuffer = StringBuffer();
    logBuffer.writeln('✅ RESPONSE');
    logBuffer.writeln('Method: $method');
    logBuffer.writeln('URL: $uri');
    logBuffer.writeln('Status Code: $statusCode');
    logBuffer.writeln('Duration: ${duration}ms');

    if (enableDetailedLogging) {
      // 记录响应头
      if (response.headers.map.isNotEmpty) {
        logBuffer.writeln('Headers:');
        response.headers.map.forEach((key, value) {
          logBuffer.writeln('  $key: ${value.join(', ')}');
        });
      }

      // 记录响应体
      if (logResponseBody && response.data != null) {
        logBuffer.writeln('Body:');
        final bodyStr = _formatData(response.data);
        logBuffer.writeln('  $bodyStr');
      }
    }

    // 一次性输出完整的日志
    Log.i(logBuffer.toString().trim(), tag: "HTTP");
  }

  /// 记录错误信息
  /// [error] 错误对象
  void _logError(DioException error) {
    final uri = error.requestOptions.uri;
    final method = error.requestOptions.method.toUpperCase();
    final duration = _calculateDuration(error.requestOptions);

    final logBuffer = StringBuffer();
    logBuffer.writeln('❌ ERROR');
    logBuffer.writeln('Method: $method');
    logBuffer.writeln('URL: $uri');
    logBuffer.writeln('Error Type: ${error.type}');
    logBuffer.writeln('Error Message: ${error.message}');
    logBuffer.writeln('Duration: ${duration}ms');

    if (error.response != null) {
      logBuffer.writeln('Status Code: ${error.response!.statusCode}');

      if (enableDetailedLogging && error.response!.data != null) {
        logBuffer.writeln('Error Body:');
        final bodyStr = _formatData(error.response!.data);
        logBuffer.writeln('  $bodyStr');
      }
    }

    // 一次性输出完整的日志
    Log.e(logBuffer.toString().trim(), tag: "HTTP");
  }

  /// 计算请求耗时
  /// [options] 请求选项
  /// 返回耗时（毫秒）
  int _calculateDuration(RequestOptions options) {
    final startTime = _requestStartTimes[options];
    if (startTime == null) {
      return 0;
    }

    final endTime = DateTime.now();
    return endTime.difference(startTime).inMilliseconds;
  }

  /// 格式化数据
  /// [data] 要格式化的数据
  String _formatData(dynamic data) {
    String dataStr;

    if (data is Map || data is List) {
      dataStr = data.toString();
    } else {
      dataStr = data?.toString() ?? 'null';
    }

    // 限制日志长度
    if (dataStr.length > maxLogLength) {
      dataStr = '${dataStr.substring(0, maxLogLength)}... (truncated)';
    }

    return dataStr;
  }
}
