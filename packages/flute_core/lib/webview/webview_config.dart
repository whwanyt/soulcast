import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'bridge/bridge_handler_factory.dart';
import 'model/webview_handler_model.dart';

/// WebView配置类
/// 提供WebView的各种配置选项和默认设置
class WebviewConfig {
  /// 初始URL
  final String? initialUrl;

  /// 用户代理字符串
  final String? userAgent;

  /// 是否启用JavaScript
  final bool javaScriptEnabled;

  /// 是否启用DOM存储
  final bool domStorageEnabled;

  /// 是否支持缩放
  final bool supportZoom;

  /// 是否显示缩放控件
  final bool displayZoomControls;

  /// 是否启用垂直滚动条
  final bool verticalScrollBarEnabled;

  /// 是否启用水平滚动条
  final bool horizontalScrollBarEnabled;

  /// 是否允许文件访问
  final bool allowFileAccess;

  /// 是否允许文件访问从文件URL
  final bool allowFileAccessFromFileURLs;

  /// 是否允许通用访问从文件URL
  final bool allowUniversalAccessFromFileURLs;

  /// 缓存模式
  final CacheMode? cacheMode;

  /// 混合内容模式
  final MixedContentMode? mixedContentMode;

  /// 是否启用安全浏览
  final bool safeBrowsingEnabled;

  /// 是否清除缓存
  final bool clearCache;

  /// 是否清除会话缓存
  final bool clearSessionCache;

  /// 是否启用硬件加速
  final bool hardwareAcceleration;

  /// 是否支持多窗口
  final bool supportMultipleWindows;

  /// 是否使用宽视口
  final bool useWideViewPort;

  /// 是否加载时概览模式
  final bool loadWithOverviewMode;

  /// 最小字体大小
  final int? minimumFontSize;

  /// 默认字体大小
  final int? defaultFontSize;

  /// 默认固定字体大小
  final int? defaultFixedFontSize;

  /// 自定义桥接处理器映射
  /// 键为事件类型，值为对应的处理器实例
  final Map<WebViewHandlerType, BaseBridgeHandler>? customBridgeHandlers;

  /// 构造函数
  const WebviewConfig({
    this.initialUrl,
    this.userAgent,
    this.javaScriptEnabled = true,
    this.domStorageEnabled = true,
    this.supportZoom = true,
    this.displayZoomControls = false,
    this.verticalScrollBarEnabled = true,
    this.horizontalScrollBarEnabled = true,
    this.allowFileAccess = true,
    this.allowFileAccessFromFileURLs = false,
    this.allowUniversalAccessFromFileURLs = false,
    this.cacheMode,
    this.mixedContentMode,
    this.safeBrowsingEnabled = true,
    this.clearCache = false,
    this.clearSessionCache = false,
    this.hardwareAcceleration = true,
    this.supportMultipleWindows = false,
    this.useWideViewPort = true,
    this.loadWithOverviewMode = true,
    this.minimumFontSize,
    this.defaultFontSize,
    this.defaultFixedFontSize,
    this.customBridgeHandlers,
  });

  /// 创建默认配置
  factory WebviewConfig.defaultConfig({String? url}) {
    return WebviewConfig(
      initialUrl: url,
      javaScriptEnabled: true,
      domStorageEnabled: true,
      supportZoom: true,
      displayZoomControls: false,
      safeBrowsingEnabled: true,
      hardwareAcceleration: true,
      useWideViewPort: true,
      loadWithOverviewMode: true,
    );
  }

  /// 创建开发环境配置
  factory WebviewConfig.developmentConfig({String? url}) {
    return WebviewConfig(
      initialUrl: url,
      javaScriptEnabled: true,
      domStorageEnabled: true,
      supportZoom: true,
      displayZoomControls: true,
      safeBrowsingEnabled: false,
      clearCache: true,
      clearSessionCache: true,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
    );
  }

  /// 创建生产环境配置
  factory WebviewConfig.productionConfig({String? url}) {
    return WebviewConfig(
      initialUrl: url,
      javaScriptEnabled: true,
      domStorageEnabled: true,
      supportZoom: false,
      displayZoomControls: false,
      safeBrowsingEnabled: true,
      clearCache: false,
      clearSessionCache: false,
      allowFileAccessFromFileURLs: false,
      allowUniversalAccessFromFileURLs: false,
    );
  }

  /// 转换为InAppWebViewSettings
  InAppWebViewSettings toInAppWebViewSettings() {
    return InAppWebViewSettings(
      userAgent: userAgent,
      javaScriptEnabled: javaScriptEnabled,
      domStorageEnabled: domStorageEnabled,
      supportZoom: supportZoom,
      displayZoomControls: displayZoomControls,
      verticalScrollBarEnabled: verticalScrollBarEnabled,
      horizontalScrollBarEnabled: horizontalScrollBarEnabled,
      allowFileAccess: allowFileAccess,
      allowFileAccessFromFileURLs: allowFileAccessFromFileURLs,
      allowUniversalAccessFromFileURLs: allowUniversalAccessFromFileURLs,
      cacheMode: cacheMode,
      mixedContentMode: mixedContentMode,
      safeBrowsingEnabled: safeBrowsingEnabled,
      hardwareAcceleration: hardwareAcceleration,
      supportMultipleWindows: supportMultipleWindows,
      useWideViewPort: useWideViewPort,
      loadWithOverviewMode: loadWithOverviewMode,
      minimumFontSize: minimumFontSize,
      defaultFontSize: defaultFontSize,
      defaultFixedFontSize: defaultFixedFontSize,
    );
  }

  /// 复制并修改配置
  WebviewConfig copyWith({
    String? initialUrl,
    String? userAgent,
    bool? javaScriptEnabled,
    bool? domStorageEnabled,
    bool? supportZoom,
    bool? displayZoomControls,
    bool? verticalScrollBarEnabled,
    bool? horizontalScrollBarEnabled,
    bool? allowFileAccess,
    bool? allowFileAccessFromFileURLs,
    bool? allowUniversalAccessFromFileURLs,
    CacheMode? cacheMode,
    MixedContentMode? mixedContentMode,
    bool? safeBrowsingEnabled,
    bool? clearCache,
    bool? clearSessionCache,
    bool? hardwareAcceleration,
    bool? supportMultipleWindows,
    bool? useWideViewPort,
    bool? loadWithOverviewMode,
    int? minimumFontSize,
    int? defaultFontSize,
    int? defaultFixedFontSize,
    Map<WebViewHandlerType, BaseBridgeHandler>? customBridgeHandlers,
  }) {
    return WebviewConfig(
      initialUrl: initialUrl ?? this.initialUrl,
      userAgent: userAgent ?? this.userAgent,
      javaScriptEnabled: javaScriptEnabled ?? this.javaScriptEnabled,
      domStorageEnabled: domStorageEnabled ?? this.domStorageEnabled,
      supportZoom: supportZoom ?? this.supportZoom,
      displayZoomControls: displayZoomControls ?? this.displayZoomControls,
      verticalScrollBarEnabled:
          verticalScrollBarEnabled ?? this.verticalScrollBarEnabled,
      horizontalScrollBarEnabled:
          horizontalScrollBarEnabled ?? this.horizontalScrollBarEnabled,
      allowFileAccess: allowFileAccess ?? this.allowFileAccess,
      allowFileAccessFromFileURLs:
          allowFileAccessFromFileURLs ?? this.allowFileAccessFromFileURLs,
      allowUniversalAccessFromFileURLs:
          allowUniversalAccessFromFileURLs ??
          this.allowUniversalAccessFromFileURLs,
      cacheMode: cacheMode ?? this.cacheMode,
      mixedContentMode: mixedContentMode ?? this.mixedContentMode,
      safeBrowsingEnabled: safeBrowsingEnabled ?? this.safeBrowsingEnabled,
      clearCache: clearCache ?? this.clearCache,
      clearSessionCache: clearSessionCache ?? this.clearSessionCache,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      supportMultipleWindows:
          supportMultipleWindows ?? this.supportMultipleWindows,
      useWideViewPort: useWideViewPort ?? this.useWideViewPort,
      loadWithOverviewMode: loadWithOverviewMode ?? this.loadWithOverviewMode,
      minimumFontSize: minimumFontSize ?? this.minimumFontSize,
      defaultFontSize: defaultFontSize ?? this.defaultFontSize,
      defaultFixedFontSize: defaultFixedFontSize ?? this.defaultFixedFontSize,
      customBridgeHandlers: customBridgeHandlers ?? this.customBridgeHandlers,
    );
  }
}
