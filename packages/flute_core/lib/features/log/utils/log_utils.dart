import 'package:flute_core/log/log_level.dart';
import 'package:flutter/material.dart';

/// 日志相关工具类
class LogUtils {
  /// 格式化日期显示
  /// [date] 要格式化的日期
  /// 返回格式化后的日期字符串
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) {
      return '今天 (${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')})';
    } else if (logDate == yesterday) {
      return '昨天 (${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')})';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化简短日期显示
  /// [date] 要格式化的日期
  /// 返回简短的日期字符串
  static String formatShortDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) {
      return '今天';
    } else if (logDate == yesterday) {
      return '昨天';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// 获取日志级别对应的颜色
  /// [level] 日志级别
  /// 返回对应的颜色
  static Color getLevelColor(LogLevel level) {
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
}
