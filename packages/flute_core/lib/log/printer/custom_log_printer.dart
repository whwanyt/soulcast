import 'package:logger/logger.dart';

/// 自定义日志格式化器
/// 确保输出格式与LogEntry解析逻辑匹配
class CustomLogPrinter extends LogPrinter {
  /// 是否启用颜色输出
  final bool enableColors;

  /// 构造函数
  /// [enableColors] 是否启用颜色输出，默认为false（文件输出不需要颜色）
  CustomLogPrinter({this.enableColors = false});

  @override
  List<String> log(LogEvent event) {
    final timestamp = _formatTimestamp(event.time);
    final level = _formatLevel(event.level);
    final tag = _extractTag(event);

    // 获取纯净的消息内容
    final message = _extractMessage(event);

    // 处理多行消息
    final messageLines = message.split('\n');
    final result = <String>[];

    // 第一行包含完整的日志头部信息
    final firstLine = '[$timestamp] [$level] [$tag] ${messageLines.first}';
    result.add(firstLine);

    // 后续行使用续行标记
    for (int i = 1; i < messageLines.length; i++) {
      if (messageLines[i].trim().isNotEmpty) {
        result.add('    ${messageLines[i]}'); // 使用缩进表示续行
      }
    }

    // 添加错误信息
    if (event.error != null) {
      result.add('  ├─ Error: ${event.error}');
    }

    // 添加堆栈跟踪（仅错误级别）
    if (event.level == Level.error && event.stackTrace != null) {
      final stackLines = event.stackTrace.toString().split('\n');
      for (int i = 0; i < stackLines.length && i < 5; i++) {
        final prefix = i == stackLines.length - 1 || i == 4 ? '  └─' : '  ├─';
        result.add('$prefix ${stackLines[i]}');
      }
    }

    return result;
  }

  /// 格式化时间戳
  /// [time] 时间对象
  String _formatTimestamp(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }

  /// 格式化日志级别
  /// [level] 日志级别
  String _formatLevel(Level level) {
    switch (level) {
      case Level.trace:
        return 'TRACE';
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO';
      case Level.warning:
        return 'WARNING';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      default:
        return 'INFO';
    }
  }

  /// 提取标签
  /// [event] 日志事件
  String _extractTag(LogEvent event) {
    final message = event.message.toString();

    // 检查自定义标签格式 [CUSTOM:TAG]
    final customTagMatch = RegExp(
      r'^\[CUSTOM:([^\]]+)\]\s*',
    ).firstMatch(message);
    if (customTagMatch != null) {
      return customTagMatch.group(1)!.toUpperCase();
    }

    // 原有的自动提取逻辑
    if (event.stackTrace != null) {
      final frames = event.stackTrace.toString().split('\n');
      for (final frame in frames) {
        if (frame.contains('package:flute_core/')) {
          final match = RegExp(
            r'package:flute_core/.*?/([^/]+)\.dart',
          ).firstMatch(frame);
          if (match != null) {
            return match.group(1)!.toUpperCase();
          }
        }
      }
    }
    return 'APP';
  }

  /// 提取消息内容
  /// [event] 日志事件
  String _extractMessage(LogEvent event) {
    String message = event.message.toString();

    // 移除自定义标签前缀
    final customTagMatch = RegExp(
      r'^\[CUSTOM:([^\]]+)\]\s*',
    ).firstMatch(message);
    if (customTagMatch != null) {
      message = message.substring(customTagMatch.end);
    }

    return message;
  }
}
