import 'dart:io';
import 'package:flute_core/log/log.dart';
import 'package:flutter/material.dart';
import '../models/log_entry.dart';

/// 日志服务类
/// 负责日志文件的读取、搜索和管理
class LogService {
  /// 单例实例
  static final LogService _instance = LogService._internal();

  /// 工厂构造函数
  factory LogService() => _instance;

  /// 私有构造函数
  LogService._internal();

  /// 获取可用的日志日期列表
  /// 返回所有存在日志文件的日期
  Future<List<DateTime>> getAvailableLogDates() async {
    try {
      final logDir = await Log.getLogDir();
      final files = logDir
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>();

      final dates = <DateTime>[];
      final dateRegex = RegExp(r'log_(\d{4}-\d{2}-\d{2})\.log');

      for (final file in files) {
        final match = dateRegex.firstMatch(file.path);
        if (match != null) {
          try {
            final date = DateTime.parse(match.group(1)!);
            dates.add(date);
          } catch (e) {
            Log.e('解析日期失败: ${match.group(1)}');
          }
        }
      }

      dates.sort((a, b) => b.compareTo(a)); // 按日期倒序排列
      return dates;
    } catch (e) {
      Log.e('获取日志日期失败: $e');
      return [];
    }
  }

  /// 读取指定日期的日志
  /// [date] 日志日期
  /// [levelFilter] 日志级别过滤器
  /// [searchKeyword] 搜索关键词
  Future<List<LogEntry>> getLogsByDate({
    required DateTime date,
    Set<LogLevel>? levelFilter,
    String? searchKeyword,
  }) async {
    try {
      final logLines = await Log.readLogsByDate(date: date);
      final entries = <LogEntry>[];

      // 按多行日志分组处理
      final multiLineGroups = _groupMultiLineEntries(logLines);

      for (final group in multiLineGroups) {
        final entry = group.length == 1
            ? LogEntry.fromLogLine(group.first)
            : LogEntry.fromMultiLineLog(group);

        if (entry == null) continue;

        // 应用级别过滤
        if (levelFilter != null && levelFilter.isNotEmpty) {
          if (!levelFilter.contains(entry.level)) continue;
        }

        // 应用搜索过滤
        if (searchKeyword != null && searchKeyword.isNotEmpty) {
          final keyword = searchKeyword.toLowerCase();
          if (!entry.message.toLowerCase().contains(keyword) &&
              !entry.tag.toLowerCase().contains(keyword)) {
            continue;
          }
        }

        entries.add(entry);
      }

      return entries;
    } catch (e) {
      Log.e('读取日志失败: $e');
      return [];
    }
  }

  // 新增方法：将日志行按多行条目分组
  List<List<String>> _groupMultiLineEntries(List<String> lines) {
    final groups = <List<String>>[];
    List<String>? currentGroup;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // 检查是否是新的日志条目（以时间戳开头）
      if (RegExp(
        r'^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]',
      ).hasMatch(line)) {
        // 保存上一个分组
        if (currentGroup != null && currentGroup.isNotEmpty) {
          groups.add(currentGroup);
        }
        // 开始新分组
        currentGroup = [line];
      } else if (currentGroup != null &&
          (line.startsWith('    ') || // 普通续行
              line.startsWith('  ├─') || // 错误信息
              line.startsWith('  └─'))) {
        // 堆栈跟踪
        // 续行内容
        currentGroup.add(line);
      }
    }

    // 添加最后一个分组
    if (currentGroup != null && currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    return groups;
  }

  /// 搜索日志
  /// [keyword] 搜索关键词
  /// [dateRange] 日期范围
  /// [levelFilter] 日志级别过滤器
  Future<List<LogEntry>> searchLogs({
    required String keyword,
    DateTimeRange? dateRange,
    Set<LogLevel>? levelFilter,
  }) async {
    if (keyword.trim().isEmpty) return [];

    try {
      final availableDates = await getAvailableLogDates();
      final searchResults = <LogEntry>[];

      for (final date in availableDates) {
        // 应用日期范围过滤
        if (dateRange != null) {
          if (date.isBefore(dateRange.start) || date.isAfter(dateRange.end)) {
            continue;
          }
        }

        final entries = await getLogsByDate(
          date: date,
          levelFilter: levelFilter,
          searchKeyword: keyword,
        );

        searchResults.addAll(entries);
      }

      // 按时间倒序排列
      searchResults.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return searchResults;
    } catch (e) {
      Log.e('搜索日志失败: $e');
      return [];
    }
  }

  /// 清理过期日志
  /// [retentionDays] 保留天数
  Future<void> cleanupOldLogs({int retentionDays = 7}) async {
    try {
      final logDir = await Log.getLogDir();
      final files = logDir
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>();

      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      final dateRegex = RegExp(r'log_(\d{4}-\d{2}-\d{2})\.log');

      for (final file in files) {
        final match = dateRegex.firstMatch(file.path);
        if (match != null) {
          try {
            final date = DateTime.parse(match.group(1)!);
            if (date.isBefore(cutoffDate)) {
              await file.delete();
              Log.i('删除过期日志: ${file.path}');
            }
          } catch (e) {
            Log.e('删除日志文件失败: ${file.path}, $e');
          }
        }
      }
    } catch (e) {
      Log.e('清理日志失败: $e');
    }
  }

  /// 导出日志
  /// [entries] 要导出的日志条目
  /// [filePath] 导出文件路径
  Future<bool> exportLogs(List<LogEntry> entries, String filePath) async {
    try {
      final file = File(filePath);
      final buffer = StringBuffer();

      buffer.writeln('# 日志导出文件');
      buffer.writeln('# 导出时间: ${DateTime.now()}');
      buffer.writeln('# 总条数: ${entries.length}');
      buffer.writeln('');

      for (final entry in entries) {
        buffer.writeln(entry.rawLine);
      }

      await file.writeAsString(buffer.toString());
      return true;
    } catch (e) {
      Log.e('导出日志失败: $e');
      return false;
    }
  }
}
