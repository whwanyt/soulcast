import 'package:flute_core/log/log.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'log_diagnostic_page.dart';
import 'services/log_service.dart';
import 'models/log_entry.dart';
import 'widgets/log_entry_widget.dart';
import 'widgets/log_filter_actions_bottom_sheet.dart';
import 'widgets/log_filter_status_bar.dart';
import 'widgets/log_search_widget.dart';
import 'widgets/log_detail_bottom_sheet.dart';

/// 日志查看页面
/// 提供日志查看、搜索、筛选等功能
class LogPage extends StatefulWidget {
  /// 构造函数
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  /// 日志服务实例
  final LogService _logService = LogService();

  /// 日志条目列表
  List<LogEntry> _logEntries = [];

  /// 可用日期列表
  List<DateTime> _availableDates = [];

  /// 当前选中的日期
  DateTime? _selectedDate;

  /// 搜索关键词
  String _searchKeyword = '';

  /// 日志级别过滤器
  Set<LogLevel> _levelFilter = {};

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否显示搜索模式
  bool _isSearchMode = false;

  /// 是否按时间正序排列（true: 正序，false: 倒序）
  bool _isAscendingOrder = false;

  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAvailableDates();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载可用日期
  Future<void> _loadAvailableDates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dates = await _logService.getAvailableLogDates();
      setState(() {
        _availableDates = dates;
        if (dates.isNotEmpty) {
          _selectedDate = dates.first;
          _loadLogs();
        }
      });
    } catch (e) {
      _showErrorSnackBar('加载日期失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载日志
  Future<void> _loadLogs() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await _logService.getLogsByDate(
        date: _selectedDate!,
        levelFilter: _levelFilter.isEmpty ? null : _levelFilter,
        searchKeyword: _searchKeyword.isEmpty ? null : _searchKeyword,
      );
      Log.i('加载日志成功: ${entries.length} 条');
      setState(() {
        _logEntries = _sortLogEntries(entries);
      });
    } catch (e) {
      _showErrorSnackBar('加载日志失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 搜索日志
  Future<void> _searchLogs() async {
    if (_searchKeyword.trim().isEmpty) {
      setState(() {
        _isSearchMode = false;
      });
      _loadLogs();
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearchMode = true;
    });

    try {
      final entries = await _logService.searchLogs(
        keyword: _searchKeyword,
        levelFilter: _levelFilter.isEmpty ? null : _levelFilter,
      );

      setState(() {
        _logEntries = _sortLogEntries(entries);
      });
    } catch (e) {
      _showErrorSnackBar('搜索失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 对日志条目进行排序
  /// [entries] 原始日志条目列表
  /// 返回排序后的日志条目列表
  List<LogEntry> _sortLogEntries(List<LogEntry> entries) {
    final sortedEntries = List<LogEntry>.from(entries);
    if (_isAscendingOrder) {
      // 正序：时间从早到晚
      sortedEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else {
      // 倒序：时间从晚到早（默认）
      sortedEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return sortedEntries;
  }

  /// 切换排序方式
  void _toggleSortOrder() {
    setState(() {
      _isAscendingOrder = !_isAscendingOrder;
      _logEntries = _sortLogEntries(_logEntries);
    });
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// 清理日志
  Future<void> _cleanupLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清理'),
        content: const Text('确定要清理7天前的日志吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _logService.cleanupOldLogs();
        _showSuccessSnackBar('日志清理完成');
        _loadAvailableDates();
      } catch (e) {
        _showErrorSnackBar('清理失败: $e');
      }
    }
  }

  /// 显示日志详情（使用底部弹窗）
  void _showLogDetail(LogEntry entry) {
    LogDetailBottomSheet.show(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          LogFilterStatusBar(
            selectedDate: _selectedDate,
            levelFilter: _levelFilter,
            onClearFilters: _clearFilters,
          ),
          Container(height: 1, color: Colors.grey[200]),
          Expanded(child: _buildLogList()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('应用日志'),
      actions: [
        IconButton(
          icon: const Icon(Icons.bug_report),
          tooltip: '日志诊断',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LogDiagnosticPage()),
          ),
        ),
      ],
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: LogSearchWidget(
        onSearch: (keyword) {
          _searchKeyword = keyword;
          _searchLogs();
        },
        onClear: () {
          _searchKeyword = '';
          setState(() {
            _isSearchMode = false;
          });
          _loadLogs();
        },
      ),
    );
  }

  /// 构建日志列表
  Widget _buildLogList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '正在加载日志...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_logEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _isSearchMode ? '未找到匹配的日志' : '暂无日志数据',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearchMode ? '尝试调整搜索条件' : '应用运行后会生成日志',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _logEntries.length,
      itemBuilder: (context, index) {
        return LogEntryWidget(
          entry: _logEntries[index],
          onTap: () => _showLogDetail(_logEntries[index]),
        );
      },
    );
  }

  /// 构建悬浮操作按钮
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showFilterAndActionsBottomSheet,
      icon: const Icon(Icons.tune),
      label: const Text('筛选与操作'),
    );
  }

  /// 显示筛选与操作底部弹窗
  void _showFilterAndActionsBottomSheet() {
    LogFilterActionsBottomSheet.show(
      context,
      LogFilterActionsBottomSheet(
        availableDates: _availableDates,
        selectedDate: _selectedDate,
        levelFilter: _levelFilter,
        isSearchMode: _isSearchMode,
        isAscendingOrder: _isAscendingOrder,
        logEntriesCount: _logEntries.length,
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
          });
          if (!_isSearchMode) {
            _loadLogs();
          }
        },
        onLevelFilterChanged: (levels) {
          setState(() {
            _levelFilter = levels;
          });
          if (_isSearchMode) {
            _searchLogs();
          } else {
            _loadLogs();
          }
        },
        onToggleSortOrder: _toggleSortOrder,
        onRefreshLogs: _isSearchMode ? null : _loadLogs,
        onCleanupLogs: _cleanupLogs,
        onExportLogs: _exportLogs,
        onClearFilters: _clearFilters,
        onQuickScroll: _logEntries.isNotEmpty
            ? () {
                // 快速滚动到列表顶部或底部
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _isAscendingOrder
                        ? _scrollController.position.maxScrollExtent
                        : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              }
            : null,
        scrollController: _scrollController,
      ),
    );
  }

  /// 导出日志到系统分享
  Future<void> _exportLogs() async {
    if (_logEntries.isEmpty) {
      _showErrorSnackBar('没有可导出的日志');
      return;
    }

    try {
      // 显示加载提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('正在准备导出文件...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 生成文件名
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'flute_logs_$timestamp.txt';

      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      // 创建导出内容
      final buffer = StringBuffer();
      buffer.writeln('# Flute 应用日志导出');
      buffer.writeln('# 导出时间: ${DateTime.now()}');
      buffer.writeln('# 日志条数: ${_logEntries.length}');
      if (_selectedDate != null) {
        buffer.writeln(
          '# 日志日期: ${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
        );
      }
      if (_levelFilter.isNotEmpty) {
        buffer.writeln('# 级别筛选: ${_levelFilter.map((e) => e.name).join(', ')}');
      }
      if (_searchKeyword.isNotEmpty) {
        buffer.writeln('# 搜索关键词: $_searchKeyword');
      }
      buffer.writeln('# ==========================================');
      buffer.writeln('');

      // 添加日志内容
      for (int i = 0; i < _logEntries.length; i++) {
        final entry = _logEntries[i];
        buffer.writeln('[$i] ${entry.rawLine}');
        if (i < _logEntries.length - 1) {
          buffer.writeln('');
        }
      }

      // 写入文件
      final file = File(filePath);
      await file.writeAsString(buffer.toString());

      // 使用最新的 SharePlus API 调用系统分享
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: '分享 Flute 应用日志文件（${_logEntries.length} 条记录）',
          subject: 'Flute 日志导出 - $fileName',
        ),
      );

      // 检查分享结果
      if (result.status == ShareResultStatus.success) {
        if (mounted) {
          _showSuccessSnackBar('日志文件已成功分享');
        }
      } else if (result.status == ShareResultStatus.dismissed) {
        if (mounted) {
          _showErrorSnackBar('分享已取消');
        }
      }

      // 清理临时文件（延迟删除，确保分享完成）
      Future.delayed(const Duration(seconds: 30), () {
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          // 忽略删除错误
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('导出失败: $e');
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _levelFilter.clear();
      _searchKeyword = '';
      _isSearchMode = false;
      _isAscendingOrder = false; // 重置为默认倒序
    });
    _loadLogs();
  }
}
