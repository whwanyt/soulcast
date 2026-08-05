import 'dart:async';

import 'package:flute_core/log/log.dart';

import '../model/webview_handler_model.dart';
import '../model/webview_result.dart';

/// WebView异常处理器
class WebViewExceptionHandler {
  static const String _tag = 'WebViewExceptionHandler';

  /// 处理JS桥接异常
  static Map<String, dynamic> handleBridgeException(
    WebViewHandlerType type,
    dynamic error,
  ) {
    final errorMessage = _formatErrorMessage(error);
    Log.e('WebView Bridge异常: $errorMessage', tag: _tag);

    return WebViewResult.error(
      type: type,
      error: errorMessage,
      code: _getErrorCode(error),
    ).toJson();
  }

  /// 处理WebView生命周期异常
  static void handleLifecycleException(String operation, dynamic error) {
    Log.e('WebView生命周期异常 [$operation]: $error', tag: _tag);
  }

  /// 格式化错误信息
  static String _formatErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString();
    }
    return error?.toString() ?? 'Unknown error';
  }

  /// 获取错误码
  static int _getErrorCode(dynamic error) {
    // 根据不同异常类型返回不同错误码
    if (error is ArgumentError) return -1001;
    if (error is StateError) return -1002;
    if (error is TimeoutException) return -1003;
    return -1000;
  }
}
