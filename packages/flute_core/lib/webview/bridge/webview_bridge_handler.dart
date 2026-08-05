import 'package:flute_core/log/log.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../model/webview_handler_model.dart';
import '../model/webview_result.dart';
import 'bridge_handler_factory.dart';

class WebviewBridgeHandler with WidgetsBindingObserver {
  WeakReference<InAppWebViewController>? _webViewControllerRef;
  InAppWebViewController? get _webViewController =>
      _webViewControllerRef?.target;

  late final List<String> _handlerNames = [];
  late final Map<WebViewHandlerType, BaseBridgeHandler> _handlers;
  late final BridgeHandlerFactory _handlerFactory;

  /// 构造函数，初始化桥接处理器工厂和处理器映射
  /// [customHandlers] 自定义处理器映射
  WebviewBridgeHandler({
    Map<WebViewHandlerType, BaseBridgeHandler>? customHandlers,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _handlerFactory = BridgeHandlerFactory(customHandlers: customHandlers);
    _handlers = _handlerFactory.createHandlers();
  }

  /// 设置WebView控制器
  void setWebViewController(InAppWebViewController controller) {
    _webViewControllerRef = WeakReference<InAppWebViewController>(controller);
  }

  /// 注册所有JS Bridge处理器
  /// 使用新的桥接处理器架构，自动注册所有支持的处理器
  void registerJsBridge() {
    final supportedEventTypes = _handlerFactory.getSupportedEventTypes();

    for (final eventType in supportedEventTypes) {
      final handler = _handlers[eventType];
      if (handler != null) {
        _registerSingleHandler(eventType, handler);
      }
    }
  }

  /// 注册单个处理器
  void _registerSingleHandler(
    WebViewHandlerType eventType,
    BaseBridgeHandler handler,
  ) {
    try {
      Log.i('注册JSBridge处理器: ${eventType.value}');
      _addJavaScriptHandler(
        handlerName: eventType.value,
        callback: (args) async {
          try {
            Map<String, dynamic> argMap = {};
            if (args.isNotEmpty) {
              final first = args.first;
              if (first is Map<String, dynamic>) {
                argMap = first;
              }
            }
            return await handler.handle(argMap);
          } catch (e) {
            Log.e('JSBridge handler error for ${eventType.value}: $e');
            return _createErrorResult(
              eventType,
              "Handler error: ${e.toString()}",
            );
          }
        },
      );
    } catch (e) {
      Log.e('注册JSBridge处理器失败: ${eventType.value}, 错误: $e');
    }
  }

  /// 添加JavaScript处理器的通用方法
  void _addJavaScriptHandler({
    required String handlerName,
    required Future<dynamic> Function(List<dynamic>) callback,
  }) {
    InAppWebViewController? controller = _webViewController;
    if (controller == null) {
      Log.w('WebView控制器为空, 无法添加JS处理器: $handlerName');
      return;
    }

    if (!_handlerNames.contains(handlerName)) {
      _handlerNames.add(handlerName);
    }

    bool isAdded = controller.hasJavaScriptHandler(handlerName: handlerName);
    if (isAdded == true) {
      Log.i('JS处理器已存在: $handlerName');
      return;
    }

    controller.addJavaScriptHandler(
      handlerName: handlerName,
      callback: (args) async {
        Log.i('JSBridge called method: $handlerName args: $args');
        return await callback(args);
      },
    );
  }

  /// 创建错误结果的辅助方法
  Map<String, dynamic> _createErrorResult(
    WebViewHandlerType type,
    String error,
  ) {
    return WebViewResult.error(type: type, error: error).toJson();
  }

  /// 获取指定类型的处理器
  BaseBridgeHandler? getHandler(WebViewHandlerType eventType) {
    return _handlers[eventType];
  }

  /// 获取所有支持的事件类型
  List<WebViewHandlerType> getSupportedEventTypes() {
    return _handlerFactory.getSupportedEventTypes();
  }

  /// 动态添加处理器
  void addHandler(WebViewHandlerType eventType, BaseBridgeHandler handler) {
    _handlers[eventType] = handler;
    _registerSingleHandler(eventType, handler);
  }

  /// 移除指定处理器
  void removeHandler(WebViewHandlerType eventType) {
    _handlers.remove(eventType);
    final handlerName = eventType.value;
    if (_handlerNames.contains(handlerName)) {
      _webViewController?.removeJavaScriptHandler(handlerName: handlerName);
      _handlerNames.remove(handlerName);
    }
  }

  /// 注销所有JS Bridge
  void unregisterAllJSBridge() {
    InAppWebViewController? controller = _webViewController;
    if (controller == null) {
      _handlerNames.clear();
      return;
    }

    for (var handlerName in _handlerNames) {
      try {
        controller.removeJavaScriptHandler(handlerName: handlerName);
      } catch (e) {
        Log.e('移除JS处理器失败 $handlerName: $e');
      }
    }
    _handlerNames.clear();
  }

  /// 释放资源
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unregisterAllJSBridge();
    _handlers.clear();
    _webViewControllerRef = null;
  }

  /// 更新自定义处理器
  /// [customHandlers] 新的自定义处理器映射
  void updateCustomHandlers(
    Map<WebViewHandlerType, BaseBridgeHandler> customHandlers,
  ) {
    // 先移除旧的处理器
    for (final eventType in _handlers.keys.toList()) {
      removeHandler(eventType);
    }

    // 重新创建处理器工厂
    _handlerFactory = BridgeHandlerFactory(customHandlers: customHandlers);
    _handlers.clear();
    _handlers.addAll(_handlerFactory.createHandlers());

    // 重新注册所有处理器
    registerJsBridge();
  }

  /// 批量添加自定义处理器
  /// [handlers] 要添加的处理器映射
  void addCustomHandlers(Map<WebViewHandlerType, BaseBridgeHandler> handlers) {
    for (final entry in handlers.entries) {
      addHandler(entry.key, entry.value);
    }
  }
}
