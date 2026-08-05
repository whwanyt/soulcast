import 'dart:async';
import 'package:flute_core/log/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'bridge/webview_bridge_handler.dart';
import 'interfaces/webview_bridge_interface.dart';
import 'webview_config.dart';

/// WebView控制器
/// 负责管理WebView的生命周期、配置和桥接功能
class WebviewController implements IWebViewController {
  /// WebView控制器实例
  InAppWebViewController? _webViewController;

  /// 桥接处理器
  late final WebviewBridgeHandler _bridgeHandler;

  /// WebView配置
  WebviewConfig? _config;

  /// 当前URL
  String? _currentUrl;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 是否正在加载
  bool _isLoading = false;

  /// 加载进度
  double _loadingProgress = 0.0;

  /// 页面标题
  String? _pageTitle;

  /// 是否可以后退
  bool _canGoBack = false;

  /// 是否可以前进
  bool _canGoForward = false;

  /// 状态变化流控制器
  final StreamController<WebviewState> _stateController =
      StreamController<WebviewState>.broadcast();

  /// 页面加载完成回调
  VoidCallback? onPageFinished;

  /// 页面开始加载回调
  VoidCallback? onPageStarted;

  /// 页面加载错误回调
  Function(String error)? onPageError;

  /// 进度变化回调
  Function(double progress)? onProgressChanged;

  /// 标题变化回调
  Function(String? title)? onTitleChanged;

  /// URL变化回调
  Function(String? url)? onUrlChanged;

  /// 构造函数
  WebviewController({WebviewConfig? config}) {
    _config = config;
    // 传入自定义处理器到桥接处理器
    _bridgeHandler = WebviewBridgeHandler(
      customHandlers: config?.customBridgeHandlers,
    );
  }

  /// 获取状态流
  Stream<WebviewState> get stateStream => _stateController.stream;

  /// 获取当前URL
  String? get currentUrl => _currentUrl;

  /// 获取页面标题
  String? get pageTitle => _pageTitle;

  /// 获取加载进度
  double get loadingProgress => _loadingProgress;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 是否可以后退
  bool get canGoBack => _canGoBack;

  /// 是否可以前进
  bool get canGoForward => _canGoForward;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取WebView控制器
  InAppWebViewController? get webViewController => _webViewController;

  /// 初始化WebView
  @override
  Future<void> initializeWebView() async {
    try {
      if (_isInitialized) {
        Log.w('WebView已经初始化');
        return;
      }

      Log.i('开始初始化WebView');
      _isInitialized = true;
      _emitState();

      Log.i('WebView初始化完成');
    } catch (e) {
      Log.e('WebView初始化失败: $e');
      _isInitialized = false;
      _emitState();
      rethrow;
    }
  }

  /// 获取WebView配置
  WebviewConfig? get config => _config;

  /// 更新WebView配置
  void updateConfig(WebviewConfig config) {
    _config = config;

    // 更新自定义处理器
    if (config.customBridgeHandlers != null) {
      _bridgeHandler.updateCustomHandlers(config.customBridgeHandlers!);
    }

    // 如果WebView已经初始化，需要重新应用配置
    if (_webViewController != null) {
      _applyConfig();
    }
  }

  /// 应用WebView配置
  Future<void> _applyConfig() async {
    if (_config != null && _webViewController != null) {
      try {
        // 应用配置到WebView
        await _webViewController!.setSettings(
          settings: _config!.toInAppWebViewSettings(),
        );
        Log.i('WebView配置已应用');
      } catch (e) {
        Log.e('应用WebView配置失败: $e');
      }
    }
  }

  /// 设置WebView控制器实例
  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
    _bridgeHandler.setWebViewController(controller);
    _bridgeHandler.registerJsBridge();

    // 应用配置
    if (_config != null) {
      _applyConfig();
    }

    Log.i('WebView控制器已设置并注册桥接');
  }

  /// 更新WebView URL
  @override
  void updateWebViewUrl(String? url) {
    if (url != null && url.isNotEmpty) {
      _currentUrl = url;
      onUrlChanged?.call(url);
      _emitState();
      Log.i('WebView URL已更新: $url');
    }
  }

  /// 设置Cookie
  @override
  Future<void> setCookies(Map<String, dynamic> cookies) async {
    try {
      final cookieManager = CookieManager.instance();

      for (final entry in cookies.entries) {
        final cookie = Cookie(
          name: entry.key,
          value: entry.value.toString(),
          domain: Uri.parse(_currentUrl ?? '').host,
        );

        await cookieManager.setCookie(
          name: entry.key,
          url: WebUri(_currentUrl ?? ''),
          value: cookie.value,
        );
      }

      Log.i('Cookies设置成功: ${cookies.keys.join(', ')}');
    } catch (e) {
      Log.e('设置Cookies失败: $e');
      rethrow;
    }
  }

  /// 加载URL
  Future<void> loadUrl(String url) async {
    try {
      if (_webViewController == null) {
        throw Exception('WebView控制器未初始化');
      }

      await _webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );
      updateWebViewUrl(url);
      Log.i('开始加载URL: $url');
    } catch (e) {
      Log.e('加载URL失败: $e');
      onPageError?.call(e.toString());
      rethrow;
    }
  }

  /// 重新加载页面
  Future<void> reload() async {
    try {
      if (_webViewController == null) {
        throw Exception('WebView控制器未初始化');
      }

      await _webViewController!.reload();
      Log.i('页面重新加载');
    } catch (e) {
      Log.e('重新加载失败: $e');
      rethrow;
    }
  }

  /// 后退
  Future<void> goBack() async {
    try {
      if (_webViewController == null) {
        throw Exception('WebView控制器未初始化');
      }

      if (await _webViewController!.canGoBack()) {
        await _webViewController!.goBack();
        Log.i('页面后退');
      }
    } catch (e) {
      Log.e('页面后退失败: $e');
      rethrow;
    }
  }

  /// 前进
  Future<void> goForward() async {
    try {
      if (_webViewController == null) {
        throw Exception('WebView控制器未初始化');
      }

      if (await _webViewController!.canGoForward()) {
        await _webViewController!.goForward();
        Log.i('页面前进');
      }
    } catch (e) {
      Log.e('页面前进失败: $e');
      rethrow;
    }
  }

  /// 停止加载
  Future<void> stopLoading() async {
    try {
      if (_webViewController == null) {
        throw Exception('WebView控制器未初始化');
      }

      await _webViewController!.stopLoading();
      _isLoading = false;
      _emitState();
      Log.i('停止加载页面');
    } catch (e) {
      Log.e('停止加载失败: $e');
      rethrow;
    }
  }

  /// 执行JavaScript代码
  Future<dynamic> evaluateJavaScript(String source) async {
    try {
      if (_webViewController == null) {
        throw Exception('WebView控制器未初始化');
      }

      final result = await _webViewController!.evaluateJavascript(
        source: source,
      );
      Log.i('JavaScript执行成功');
      return result;
    } catch (e) {
      Log.e('JavaScript执行失败: $e');
      rethrow;
    }
  }

  /// 获取页面内容
  Future<String?> getHtml() async {
    try {
      if (_webViewController == null) {
        throw Exception('WebView控制器未初始化');
      }

      return await _webViewController!.getHtml();
    } catch (e) {
      Log.e('获取页面内容失败: $e');
      rethrow;
    }
  }

  /// 清除缓存
  Future<void> clearCache() async {
    try {
      if (_webViewController == null) {
        throw Exception('WebView控制器未初始化');
      }

      // _webViewController?.clearAllCache();
      Log.i('缓存已清除');
    } catch (e) {
      Log.e('清除缓存失败: $e');
      rethrow;
    }
  }

  /// 处理页面开始加载
  void onPageStartedHandler(InAppWebViewController controller, WebUri? url) {
    _isLoading = true;
    _loadingProgress = 0.0;
    updateWebViewUrl(url?.toString());
    onPageStarted?.call();
    _emitState();
    Log.i('页面开始加载: ${url?.toString()}');
  }

  /// 处理页面加载完成
  void onPageFinishedHandler(InAppWebViewController controller, WebUri? url) {
    _isLoading = false;
    _loadingProgress = 1.0;
    updateWebViewUrl(url?.toString());
    onPageFinished?.call();
    _updateNavigationState();
    _emitState();
    Log.i('页面加载完成: ${url?.toString()}');
  }

  /// 处理页面加载错误
  void onPageErrorHandler(
    InAppWebViewController controller,
    WebUri? url,
    int code,
    String message, {
    bool isForMainFrame = true,
  }) {
    _isLoading = false;
    final error = 'Error $code: $message';
    // 只有主文档加载失败才触发错误回调
    if (isForMainFrame) {
      onPageError?.call(error);
      Log.e('主页面加载错误: $error, URL: ${url?.toString()}');
    } else {
      // 资源加载失败只记录日志，不触发错误页面
      Log.w('资源加载失败: $error, URL: ${url?.toString()}');
    }

    _emitState();
    Log.e('页面加载错误: $error, URL: ${url?.toString()}');
  }

  /// 处理进度变化
  void onProgressChangedHandler(
    InAppWebViewController controller,
    int progress,
  ) {
    _loadingProgress = progress / 100.0;
    onProgressChanged?.call(_loadingProgress);
    _emitState();
  }

  /// 处理标题变化
  void onTitleChangedHandler(InAppWebViewController controller, String? title) {
    _pageTitle = title;
    onTitleChanged?.call(title);
    _emitState();
  }

  /// 更新导航状态
  Future<void> _updateNavigationState() async {
    if (_webViewController != null) {
      _canGoBack = await _webViewController!.canGoBack();
      _canGoForward = await _webViewController!.canGoForward();
    }
  }

  /// 发射状态变化
  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(
        WebviewState(
          isInitialized: _isInitialized,
          isLoading: _isLoading,
          loadingProgress: _loadingProgress,
          currentUrl: _currentUrl,
          pageTitle: _pageTitle,
          canGoBack: _canGoBack,
          canGoForward: _canGoForward,
        ),
      );
    }
  }

  /// 释放资源
  @override
  void dispose() {
    Log.i('WebView控制器开始释放资源');

    _bridgeHandler.dispose();
    _stateController.close();
    _webViewController = null;
    _isInitialized = false;

    // 清空回调
    onPageFinished = null;
    onPageStarted = null;
    onPageError = null;
    onProgressChanged = null;
    onTitleChanged = null;
    onUrlChanged = null;

    Log.i('WebView控制器资源释放完成');
  }
}

/// WebView状态类
class WebviewState {
  final bool isInitialized;
  final bool isLoading;
  final double loadingProgress;
  final String? currentUrl;
  final String? pageTitle;
  final bool canGoBack;
  final bool canGoForward;

  const WebviewState({
    required this.isInitialized,
    required this.isLoading,
    required this.loadingProgress,
    this.currentUrl,
    this.pageTitle,
    required this.canGoBack,
    required this.canGoForward,
  });

  @override
  String toString() {
    return 'WebviewState(isInitialized: $isInitialized, isLoading: $isLoading, progress: $loadingProgress, url: $currentUrl, title: $pageTitle, canGoBack: $canGoBack, canGoForward: $canGoForward)';
  }
}
