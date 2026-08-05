import 'package:logger/logger.dart';
import '../printer/custom_log_printer.dart';
import 'isolate_file_output.dart';
import '../log_config.dart';

/// 文件专用日志输出
/// 使用自定义格式化器确保格式一致性
class FileLogOutput extends LogOutput {
  /// 底层文件输出
  final IsolateFileOutput _fileOutput;

  /// 自定义格式化器
  final CustomLogPrinter _printer = CustomLogPrinter();

  /// 构造函数
  /// [config] 日志配置
  FileLogOutput(LogConfig config) : _fileOutput = IsolateFileOutput(config);

  /// 获取底层文件输出实例
  /// 用于创建 SilentFileOutput
  IsolateFileOutput get isolateFileOutput => _fileOutput;

  /// 初始化
  @override
  Future<void> init() async {
    await _fileOutput.init();
  }

  @override
  void output(OutputEvent event) {
    // 使用自定义格式化器重新格式化
    final formattedLines = _printer.log(event.origin);

    // 创建新的输出事件
    final newEvent = OutputEvent(event.origin, formattedLines);

    // 输出到文件
    _fileOutput.output(newEvent);
  }

  /// 销毁
  @override
  Future<void> destroy() async {
    await _fileOutput.destroy();
  }
}
