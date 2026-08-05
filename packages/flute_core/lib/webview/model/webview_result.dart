import 'dart:convert';

import 'webview_handler_model.dart';

/// WebView结果包装类
class WebViewResult {
  final WebViewHandlerType type;
  final Map<String, dynamic>? result;
  final String? error;
  final int? code;

  WebViewResult.success({required this.type, this.result})
    : error = null,
      code = 200;

  WebViewResult.error({required this.type, this.error, this.code = -1})
    : result = null;

  WebViewResult({required this.type, this.result, this.error, this.code});

  /// 转换为JSON字符串
  String toJsonStr() {
    return json.encode({
      "type": type.value,
      "result": result,
      "error": error,
      "code": code,
    });
  }

  /// 转换为Map
  Map<String, dynamic> toJson() {
    return {"type": type.value, "result": result, "error": error, "code": code};
  }
}
