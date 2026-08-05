import 'package:flute_core/log/log_level.dart';
import 'package:flutter/material.dart';

/// 日志条目模型
/// 表示单条日志记录的数据结构
class LogEntry {
  /// 日志时间戳
  final DateTime timestamp;

  /// 日志级别
  final LogLevel level;

  /// 日志标签
  final String tag;

  /// 日志消息内容
  final String message;

  /// 原始日志行
  final String rawLine;

  /// 构造函数
  /// [timestamp] 日志时间戳
  /// [level] 日志级别
  /// [tag] 日志标签
  /// [message] 日志消息内容
  /// [rawLine] 原始日志行
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    required this.rawLine,
  });

  /// 从日志行解析日志条目
  /// [line] 日志行字符串
  static LogEntry? fromLogLine(String line) {
    try {
      // 解析日志格式: [时间] [级别] [标签] 消息
      final regex = RegExp(
        r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]\s*\[(\w+)\]\s*\[([^\]]+)\]\s*(.+)',
      );
      final match = regex.firstMatch(line);

      if (match != null) {
        final timestampStr = match.group(1)!;
        final levelStr = match.group(2)!;
        final tag = match.group(3)!;
        final message = match.group(4)!;

        final timestamp = DateTime.parse(timestampStr.replaceAll(' ', 'T'));
        final level = _parseLogLevel(levelStr);

        return LogEntry(
          timestamp: timestamp,
          level: level,
          tag: tag,
          message: message,
          rawLine: line,
        );
      }
    } catch (e) {
      // 解析失败时返回简单格式
      return LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        tag: 'UNKNOWN',
        message: line,
        rawLine: line,
      );
    }
    return null;
  }

  // 新增方法：从多行日志解析
  static LogEntry? fromMultiLineLog(List<String> lines) {
    if (lines.isEmpty) return null;

    // 解析第一行获取基本信息
    final firstEntry = fromLogLine(lines.first);
    if (firstEntry == null) return null;

    // 合并所有行的消息内容
    final messageBuffer = StringBuffer(firstEntry.message);
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      // 处理不同类型的续行格式
      if (line.startsWith('    ') || // 普通续行
          line.startsWith('  ├─') || // 错误信息
          line.startsWith('  └─')) {
        // 堆栈跟踪结束
        messageBuffer.writeln();
        if (line.startsWith('    ')) {
          messageBuffer.write(line.substring(4)); // 移除缩进
        } else {
          messageBuffer.write(line.substring(2)); // 移除错误信息前缀
        }
      }
    }

    return LogEntry(
      timestamp: firstEntry.timestamp,
      level: firstEntry.level,
      tag: firstEntry.tag,
      message: messageBuffer.toString(),
      rawLine: lines.join('\n'),
    );
  }

  /// 解析日志级别字符串
  /// [levelStr] 日志级别字符串
  static LogLevel _parseLogLevel(String levelStr) {
    switch (levelStr.toUpperCase()) {
      case 'TRACE':
        return LogLevel.trace;
      case 'DEBUG':
        return LogLevel.debug;
      case 'INFO':
        return LogLevel.info;
      case 'WARNING':
      case 'WARN':
        return LogLevel.warning;
      case 'ERROR':
        return LogLevel.error;
      case 'FATAL':
        return LogLevel.fatal;
      default:
        return LogLevel.info;
    }
  }

  /// 获取日志级别颜色
  /// 返回对应日志级别的显示颜色
  Color get levelColor {
    switch (level) {
      case LogLevel.trace:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.fatal:
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  /// 获取日志级别图标
  /// 返回对应日志级别的显示图标
  IconData get levelIcon {
    switch (level) {
      case LogLevel.trace:
        return Icons.timeline;
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
      case LogLevel.fatal:
        return Icons.dangerous;
      default:
        return Icons.circle;
    }
  }
}
