import 'package:logger/logger.dart';

/// 支持标签的Logger包装器
/// 提供标签传递功能而不修改消息内容
class TaggedLogger {
  /// 内部Logger实例
  final Logger _logger;

  /// 构造函数
  /// [logger] Logger实例
  TaggedLogger(this._logger);

  /// 记录带标签的日志
  /// [level] 日志级别
  /// [message] 日志消息
  /// [tag] 自定义标签
  /// [error] 错误对象
  /// [stackTrace] 堆栈跟踪
  void logWithTag(
    Level level,
    dynamic message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // 创建带标签前缀的消息
    final taggedMessage = tag != null ? '[CUSTOM:$tag] $message' : message;

    // 直接使用Logger的方法
    switch (level) {
      case Level.debug:
        _logger.d(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.info:
        _logger.i(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.warning:
        _logger.w(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.error:
        _logger.e(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      default:
        _logger.i(taggedMessage, error: error, stackTrace: stackTrace);
    }
  }

  /// 调试日志
  /// [message] 日志消息
  /// [tag] 自定义标签
  void d(dynamic message, {String? tag}) {
    if (tag != null) {
      logWithTag(Level.debug, message, tag: tag);
    } else {
      _logger.d(message);
    }
  }

  /// 信息日志
  /// [message] 日志消息
  /// [tag] 自定义标签
  void i(dynamic message, {String? tag}) {
    if (tag != null) {
      logWithTag(Level.info, message, tag: tag);
    } else {
      _logger.i(message);
    }
  }

  /// 警告日志
  /// [message] 日志消息
  /// [tag] 自定义标签
  void w(dynamic message, {String? tag}) {
    if (tag != null) {
      logWithTag(Level.warning, message, tag: tag);
    } else {
      _logger.w(message);
    }
  }

  /// 错误日志
  /// [message] 日志消息
  /// [error] 错误对象
  /// [stackTrace] 堆栈跟踪
  /// [tag] 自定义标签
  void e(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (tag != null) {
      logWithTag(
        Level.error,
        message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
