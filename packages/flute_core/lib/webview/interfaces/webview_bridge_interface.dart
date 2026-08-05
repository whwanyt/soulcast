import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView桥接接口抽象
abstract class IWebViewBridge {
  /// 注册JS桥接方法
  void registerJsBridge();

  /// 注销所有JS桥接
  void unregisterAllJSBridge();

  /// 设置WebView控制器
  void setWebViewController(InAppWebViewController controller);

  /// 释放资源
  void dispose();
}

/// WebView控制器接口抽象
abstract class IWebViewController {
  /// 初始化WebView
  Future<void> initializeWebView();

  /// 更新WebView URL
  void updateWebViewUrl(String? url);

  /// 设置Cookie
  Future<void> setCookies(Map<String, dynamic> cookies);

  /// 释放资源
  void dispose();
}
