import 'package:logger/logger.dart';

/// 带标签的日志事件
/// 扩展LogEvent以支持自定义标签传递
class TaggedLogEvent extends LogEvent {
  /// 自定义标签
  final String? customTag;

  /// 构造函数
  /// [level] 日志级别
  /// [message] 日志消息
  /// [customTag] 自定义标签
  /// [error] 错误对象
  /// [stackTrace] 堆栈跟踪
  /// [time] 时间戳
  TaggedLogEvent(
    super.level,
    super.message, {
    this.customTag,
    super.error,
    super.stackTrace,
    super.time,
  });
}
