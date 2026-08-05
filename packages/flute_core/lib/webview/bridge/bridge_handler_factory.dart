import '../model/webview_handler_model.dart';
import '../model/webview_result.dart';

class BridgeHandlerFactory {
  /// 自定义处理器映射
  final Map<WebViewHandlerType, BaseBridgeHandler>? _customHandlers;

  /// 构造函数
  /// [customHandlers] 外部传入的自定义处理器映射
  BridgeHandlerFactory({
    this._customHandlers,
  });

  /// 创建所有桥接处理器的映射
  /// 合并默认处理器和自定义处理器
  Map<WebViewHandlerType, BaseBridgeHandler> createHandlers() {
    final Map<WebViewHandlerType, BaseBridgeHandler> handlers = {};

    // 添加默认处理器（如果有的话）
    handlers.addAll(_createDefaultHandlers());

    // 添加自定义处理器，自定义处理器会覆盖同类型的默认处理器
    if (_customHandlers != null) {
      handlers.addAll(_customHandlers);
    }

    return handlers;
  }

  /// 创建默认处理器映射
  /// 子类可以重写此方法来提供默认的处理器实现
  Map<WebViewHandlerType, BaseBridgeHandler> _createDefaultHandlers() {
    return {
      // 这里可以添加默认的处理器实现
      // WebViewHandlerType.closeWebView: DefaultCloseWebViewHandler(),
    };
  }

  /// 获取单个处理器
  /// [eventType] 事件类型
  BaseBridgeHandler? getHandler(WebViewHandlerType eventType) {
    final handlers = createHandlers();
    return handlers[eventType];
  }

  /// 获取所有支持的事件类型
  List<WebViewHandlerType> getSupportedEventTypes() {
    final handlers = createHandlers();
    return handlers.keys.toList();
  }

  /// 检查是否支持指定的事件类型
  bool isSupported(WebViewHandlerType eventType) {
    return getSupportedEventTypes().contains(eventType);
  }

  /// 添加自定义处理器
  /// [eventType] 事件类型
  /// [handler] 处理器实例
  void addCustomHandler(
    WebViewHandlerType eventType,
    BaseBridgeHandler handler,
  ) {
    _customHandlers?[eventType] = handler;
  }

  /// 移除自定义处理器
  /// [eventType] 事件类型
  void removeCustomHandler(WebViewHandlerType eventType) {
    _customHandlers?.remove(eventType);
  }
}

/// 桥接处理器基础接口
abstract class BaseBridgeHandler {
  /// 处理请求的主入口方法
  Future<Map<String, dynamic>?> handle(Map<String, dynamic> args);

  /// 获取事件类型
  WebViewHandlerType getEventType();
}

/// 桥接处理器基类 - 带泛型的具体实现
abstract class BridgeHandler<TRequest, TResult> implements BaseBridgeHandler {
  /// 处理请求的主入口方法
  @override
  Future<Map<String, dynamic>?> handle(Map<String, dynamic> args) async {
    try {
      // 解析请求参数
      final request = parseRequest(args);

      // 执行业务逻辑
      final result = await execute(request);

      if (result == null) {
        return WebViewResult.success(type: getEventType()).toJson();
      }
      // 创建成功结果
      return createSuccessResult(getEventType(), result);
    } catch (e) {
      return createErrorResult(getEventType(), e.toString());
    }
  }

  /// 解析请求参数 - 子类必须实现
  TRequest parseRequest(Map<String, dynamic> args);

  /// 执行具体的业务逻辑 - 子类必须实现
  Future<TResult?> execute(TRequest request);

  /// 创建成功结果
  /// 将结果对象转换为可序列化的格式后传递给 WebViewResult
  Map<String, dynamic> createSuccessResult(
    WebViewHandlerType type,
    TResult result,
  ) {
    final serializedResult = _convertToSerializableData(result);
    return WebViewResult.success(type: type, result: serializedResult).toJson();
  }

  /// 创建错误结果
  Map<String, dynamic> createErrorResult(
    WebViewHandlerType type,
    String error,
  ) {
    return WebViewResult.error(type: type, error: error).toJson();
  }

  /// 将结果转换为可序列化的数据
  /// 确保所有对象都能被正确序列化为 JSON
  dynamic _convertToSerializableData(TResult result) {
    if (result == null) {
      return null;
    }

    // 如果已经是基本数据类型，直接返回
    if (result is String || result is num || result is bool) {
      return result;
    }

    // 如果是 Map，直接返回
    if (result is Map<String, dynamic>) {
      return result;
    }

    // 如果是 List，递归处理每个元素
    if (result is List) {
      return result.map((item) => _convertToSerializableData(item)).toList();
    }

    // 尝试调用 toJson 方法
    try {
      final dynamic resultDynamic = result;
      if (resultDynamic.runtimeType.toString().contains('toJson')) {
        return resultDynamic.toJson();
      }
    } catch (e) {
      // 如果 toJson 调用失败，继续尝试其他方法
    }

    // 使用反射检查是否有 toJson 方法
    try {
      final dynamic resultDynamic = result;
      final toJsonMethod = resultDynamic.toJson;
      if (toJsonMethod != null) {
        return toJsonMethod();
      }
    } catch (e) {
      // 如果反射调用失败，使用 toString 作为后备方案
    }

    // 后备方案：转换为字符串
    return result.toString();
  }
}
