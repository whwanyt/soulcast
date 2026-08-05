import 'package:logger/logger.dart';

/// 控制台日志格式化器
/// 为控制台输出提供彩色和美观的格式
class ConsoleLogPrinter extends LogPrinter {
  /// ANSI颜色代码
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _gray = '\x1B[90m';

  @override
  List<String> log(LogEvent event) {
    final timestamp = _formatTimestamp(event.time);
    final level = _formatLevel(event.level);
    final tag = _extractTag(event);

    // 获取纯净的消息内容
    final message = _extractMessage(event);

    final color = _getLevelColor(event.level);
    final logLine =
        '$_gray$timestamp$_reset $color$level$_reset $_cyan[$tag]$_reset $message';

    final lines = [logLine];

    // 添加错误信息
    if (event.error != null) {
      lines.add('$_red  ├─ Error: ${event.error}$_reset');
    }

    // 添加堆栈跟踪（仅错误级别）
    if (event.level == Level.error && event.stackTrace != null) {
      final stackLines = event.stackTrace.toString().split('\n');
      for (int i = 0; i < stackLines.length && i < 5; i++) {
        final prefix = i == stackLines.length - 1 || i == 4 ? '  └─' : '  ├─';
        lines.add('$_gray$prefix ${stackLines[i]}$_reset');
      }
    }

    return lines;
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

  /// 格式化时间戳
  /// [time] 时间对象
  String _formatTimestamp(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  /// 格式化日志级别
  /// [level] 日志级别
  String _formatLevel(Level level) {
    switch (level) {
      case Level.trace:
        return 'TRC';
      case Level.debug:
        return 'DBG';
      case Level.info:
        return 'INF';
      case Level.warning:
        return 'WRN';
      case Level.error:
        return 'ERR';
      case Level.fatal:
        return 'FTL';
      default:
        return 'INF';
    }
  }

  /// 获取级别颜色
  /// [level] 日志级别
  String _getLevelColor(Level level) {
    switch (level) {
      case Level.trace:
        return _gray;
      case Level.debug:
        return _blue;
      case Level.info:
        return _green;
      case Level.warning:
        return _yellow;
      case Level.error:
        return _red;
      case Level.fatal:
        return _magenta;
      default:
        return _reset;
    }
  }
}
