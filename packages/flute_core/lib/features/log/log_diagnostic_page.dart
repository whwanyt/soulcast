import 'dart:io';
import 'package:flute_core/log/log.dart';
import 'package:flutter/material.dart';

/// 日志诊断页面
/// 用于测试和排查日志写入、读取问题
class LogDiagnosticPage extends StatefulWidget {
  /// 构造函数
  const LogDiagnosticPage({super.key});

  @override
  State<LogDiagnosticPage> createState() => _LogDiagnosticPageState();
}

class _LogDiagnosticPageState extends State<LogDiagnosticPage> {
  /// 诊断结果
  final List<String> _diagnosticResults = [];

  /// 是否正在诊断
  bool _isDiagnosing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日志诊断工具')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '日志系统诊断',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '此工具将测试日志写入和读取功能，帮助排查问题',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isDiagnosing ? null : _runDiagnostic,
                      child: _isDiagnosing
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('诊断中...'),
                              ],
                            )
                          : const Text('开始诊断'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '诊断结果',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _diagnosticResults.isEmpty
                            ? const Center(
                                child: Text(
                                  '点击"开始诊断"按钮开始测试',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _diagnosticResults.length,
                                itemBuilder: (context, index) {
                                  final result = _diagnosticResults[index];
                                  final isError = result.startsWith('❌');
                                  final isSuccess = result.startsWith('✅');
                                  final isInfo = result.startsWith('ℹ️');

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      result,
                                      style: TextStyle(
                                        color: isError
                                            ? Colors.red
                                            : isSuccess
                                            ? Colors.green
                                            : isInfo
                                            ? Colors.blue
                                            : Colors.black87,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 运行诊断测试
  Future<void> _runDiagnostic() async {
    setState(() {
      _isDiagnosing = true;
      _diagnosticResults.clear();
    });

    _addResult('🔍 开始日志系统诊断...');

    try {
      // 1. 检查日志目录
      await _checkLogDirectory();

      // 2. 测试日志写入
      await _testLogWriting();

      // 3. 等待文件写入完成
      await _waitForFileWrite();

      // 4. 测试日志读取
      await _testLogReading();

      // 5. 检查日志文件内容
      await _checkLogFileContent();

      _addResult('✅ 诊断完成');
    } catch (e) {
      _addResult('❌ 诊断过程中发生错误: $e');
    } finally {
      setState(() {
        _isDiagnosing = false;
      });
    }
  }

  /// 检查日志目录
  Future<void> _checkLogDirectory() async {
    try {
      final dir = await Log.getLogDir();
      _addResult('ℹ️ 日志目录: ${dir.path}');

      if (await dir.exists()) {
        _addResult('✅ 日志目录存在');

        // 列出目录中的日志文件
        final files = await dir
            .list()
            .where((f) => f.path.endsWith('.log'))
            .toList();
        _addResult('ℹ️ 找到 ${files.length} 个日志文件');

        for (final file in files) {
          final fileName = file.path.split('/').last;
          final stat = await file.stat();
          _addResult('  📄 $fileName (${stat.size} bytes)');
        }
      } else {
        _addResult('❌ 日志目录不存在');
      }
    } catch (e) {
      _addResult('❌ 检查日志目录失败: $e');
    }
  }

  /// 测试日志写入
  Future<void> _testLogWriting() async {
    try {
      final testMessage = '诊断测试消息 - ${DateTime.now().millisecondsSinceEpoch}';

      _addResult('ℹ️ 测试日志写入...');

      // 写入不同级别的日志
      Log.d('DEBUG: $testMessage');
      Log.i('INFO: $testMessage');
      Log.w('WARNING: $testMessage');
      Log.e('ERROR: $testMessage');

      _addResult('✅ 日志写入命令已发送');
    } catch (e) {
      _addResult('❌ 日志写入失败: $e');
    }
  }

  /// 等待文件写入完成
  Future<void> _waitForFileWrite() async {
    _addResult('ℹ️ 等待文件写入完成...');

    // 等待足够的时间让isolate处理日志
    await Future.delayed(const Duration(seconds: 6));

    _addResult('✅ 等待完成');
  }

  /// 测试日志读取
  Future<void> _testLogReading() async {
    try {
      _addResult('ℹ️ 测试日志读取...');

      final today = DateTime.now();
      final logLines = await Log.readLogsByDate(date: today);

      _addResult('✅ 成功读取 ${logLines.length} 行日志');

      if (logLines.isNotEmpty) {
        _addResult('ℹ️ 最新几行日志:');
        final recentLines = logLines.take(3).toList();
        for (int i = 0; i < recentLines.length; i++) {
          final line = recentLines[i];
          final truncated = line.length > 80
              ? '${line.substring(0, 80)}...'
              : line;
          _addResult('  ${i + 1}. $truncated');
        }
      }
    } catch (e) {
      _addResult('❌ 日志读取失败: $e');
    }
  }

  /// 检查日志文件内容
  Future<void> _checkLogFileContent() async {
    try {
      _addResult('ℹ️ 检查今日日志文件...');

      final dir = await Log.getLogDir();
      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final logFile = File('${dir.path}/log_$dateStr.log');

      if (await logFile.exists()) {
        final stat = await logFile.stat();
        final content = await logFile.readAsString();
        final lines = content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();

        _addResult('✅ 日志文件存在: log_$dateStr.log');
        _addResult('ℹ️ 文件大小: ${stat.size} bytes');
        _addResult('ℹ️ 文件行数: ${lines.length}');
        _addResult('ℹ️ 最后修改: ${stat.modified}');

        // 检查是否包含测试消息
        final testLines = lines
            .where((line) => line.contains('诊断测试消息'))
            .toList();
        if (testLines.isNotEmpty) {
          _addResult('✅ 找到 ${testLines.length} 条测试日志');
        } else {
          _addResult('⚠️ 未找到测试日志，可能写入延迟');
        }
      } else {
        _addResult('❌ 今日日志文件不存在: log_$dateStr.log');
      }
    } catch (e) {
      _addResult('❌ 检查日志文件失败: $e');
    }
  }

  /// 添加诊断结果
  /// [result] 结果信息
  void _addResult(String result) {
    setState(() {
      _diagnosticResults.add(result);
    });
  }
}
