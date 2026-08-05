import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:logger/logger.dart';

import 'filter/log_filter.dart';
import 'log_config.dart';
import 'log_level.dart';
import 'output/file_log_output.dart';
import 'output/silent_file_output.dart';
import 'printer/console_log_printer.dart';
import 'tagged_logger.dart';

class Log {
  static Logger? _logger;
  static TaggedLogger? _taggedLogger;
  static late LogConfig _config;
  static late SilentFileOutput _silentOutput;

  static Future<void> init(LogConfig config) async {
    _config = config;
    List<LogOutput> outputs = [ConsoleOutput()];

    if (config.canWriteToFile) {
      final fileOutput = FileLogOutput(config);
      await fileOutput.init();
      outputs.add(fileOutput);

      _silentOutput = SilentFileOutput(fileOutput.isolateFileOutput);
    }

    if (config.output != null) {
      outputs = [...outputs, ...config.output!];
    }

    _logger = Logger(
      filter: ComLogFilter(LevelAdapter.toLevel(config.logLevel)),
      printer: ConsoleLogPrinter(),
      output: MultiOutput(outputs),
    );

    _taggedLogger = TaggedLogger(_logger!);
  }

  static Future<Directory> getLogDir() async {
    if (_config.logDirectory == null) {
      throw Exception('Log directory not configured');
    }
    return _config.logDirectory!;
  }

  static Future<List<String>> readLogsByDate({DateTime? date}) async {
    if (!_config.canWriteToFile) {
      return [];
    }

    date ??= DateTime.now();
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final file = File('${_config.logDirectory!.path}/log_$dateStr.log');
    if (await file.exists()) {
      return await file.readAsLines();
    }
    return [];
  }

  static void console(
    String message, {
    DateTime? time,
    int level = 500,
    String name = '',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logLevel = _developerLevelToLoggerLevel(level);

    developer.log(
      message,
      time: time ?? DateTime.now(),
      level: level,
      name: name.isNotEmpty ? name : 'CONSOLE',
      error: error,
      stackTrace: stackTrace,
    );

    if (_config.canWriteToFile) {
      try {
        final outputEvent = OutputEvent(
          LogEvent(
            logLevel,
            message,
            error: error,
            stackTrace: stackTrace,
            time: time,
          ),
          [message.toString()],
        );
        _silentOutput.output(outputEvent);
      } catch (e) {
        developer.log('日志写入失败: $e');
      }
    }
  }

  /// 映射枚举
  static Level _developerLevelToLoggerLevel(int developerLevel) {
    return switch (developerLevel) {
      >= 1000 => Level.error,
      >= 900 => Level.warning,
      >= 800 => Level.info,
      >= 500 => Level.debug,
      _ => Level.all,
    };
  }

  /// 调试日志
  /// [message] 日志消息
  /// [tag] 自定义标签，如果不提供则自动提取
  static void d(dynamic message, {String? tag}) {
    _taggedLogger?.d(message, tag: tag);
  }

  /// 信息日志
  /// [message] 日志消息
  /// [tag] 自定义标签，如果不提供则自动提取
  static void i(dynamic message, {String? tag}) {
    _taggedLogger?.i(message, tag: tag);
  }

  /// 警告日志
  /// [message] 日志消息
  /// [tag] 自定义标签，如果不提供则自动提取
  static void w(dynamic message, {String? tag}) {
    _taggedLogger?.w(message, tag: tag);
  }

  /// 错误日志
  /// [message] 日志消息
  /// [error] 错误对象
  /// [stackTrace] 堆栈跟踪
  /// [tag] 自定义标签，如果不提供则自动提取
  static void e(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _taggedLogger?.e(message, error: error, stackTrace: stackTrace, tag: tag);
  }
}
