import 'package:flute_core/log/log_level.dart';
import 'package:flutter/material.dart';
import 'log_actions_section.dart';
import 'log_filter_section.dart';

/// 日志筛选与操作底部弹窗组件
/// 提供日志筛选条件设置和操作功能
class LogFilterActionsBottomSheet extends StatefulWidget {
  /// 可用日期列表
  final List<DateTime> availableDates;

  /// 当前选中的日期
  final DateTime? selectedDate;

  /// 当前级别筛选器
  final Set<LogLevel> levelFilter;

  /// 是否为搜索模式
  final bool isSearchMode;

  /// 是否为正序排列
  final bool isAscendingOrder;

  /// 日志条目数量
  final int logEntriesCount;

  /// 日期变更回调
  final Function(DateTime?) onDateChanged;

  /// 级别筛选变更回调
  final Function(Set<LogLevel>) onLevelFilterChanged;

  /// 排序切换回调
  final VoidCallback onToggleSortOrder;

  /// 刷新日志回调
  final VoidCallback? onRefreshLogs;

  /// 清理日志回调
  final VoidCallback onCleanupLogs;

  /// 导出日志回调
  final VoidCallback onExportLogs;

  /// 清除筛选回调
  final VoidCallback onClearFilters;

  /// 快速滚动回调
  final VoidCallback? onQuickScroll;

  /// 滚动控制器
  final ScrollController scrollController;

  /// 构造函数
  const LogFilterActionsBottomSheet({
    super.key,
    required this.availableDates,
    required this.selectedDate,
    required this.levelFilter,
    required this.isSearchMode,
    required this.isAscendingOrder,
    required this.logEntriesCount,
    required this.onDateChanged,
    required this.onLevelFilterChanged,
    required this.onToggleSortOrder,
    required this.onRefreshLogs,
    required this.onCleanupLogs,
    required this.onExportLogs,
    required this.onClearFilters,
    required this.onQuickScroll,
    required this.scrollController,
  });

  /// 显示底部弹窗
  /// [context] 上下文
  /// [config] 配置参数
  static void show(BuildContext context, LogFilterActionsBottomSheet config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      showDragHandle: false,
      builder: (context) => config,
    );
  }

  @override
  State<LogFilterActionsBottomSheet> createState() =>
      _LogFilterActionsBottomSheetState();
}

class _LogFilterActionsBottomSheetState
    extends State<LogFilterActionsBottomSheet> {
  /// 当前选中的日期
  late DateTime? _selectedDate;

  /// 当前级别筛选器
  late Set<LogLevel> _levelFilter;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _levelFilter = Set.from(widget.levelFilter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDragHandle(colorScheme),
          _buildHeader(theme, colorScheme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(),
                  const SizedBox(height: 24),
                  _buildActionsSection(),
                  // 底部安全区域
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建拖拽手柄
  /// [colorScheme] 颜色方案
  Widget _buildDragHandle(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// 构建弹窗头部
  /// [theme] 主题数据
  /// [colorScheme] 颜色方案
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '筛选与操作',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.logEntriesCount > 0)
                  Text(
                    '当前显示 ${widget.logEntriesCount} 条日志',
                    style: theme.textTheme.bodySmall?.copyWith(),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  /// 构建筛选条件区域
  Widget _buildFilterSection() {
    return LogFilterSection(
      availableDates: widget.availableDates,
      selectedDate: _selectedDate,
      levelFilter: _levelFilter,
      isSearchMode: widget.isSearchMode,
      onDateChanged: (date) {
        setState(() {
          _selectedDate = date;
        });
        widget.onDateChanged(date);
      },
      onLevelFilterChanged: (levels) {
        setState(() {
          _levelFilter = levels;
        });
        widget.onLevelFilterChanged(levels);
      },
      onClearAll: () {
        setState(() {
          _levelFilter.clear();
          _selectedDate = null;
        });
        widget.onLevelFilterChanged({});
        widget.onClearFilters();
      },
    );
  }

  /// 构建操作功能区域
  Widget _buildActionsSection() {
    return LogActionsSection(
      isAscendingOrder: widget.isAscendingOrder,
      isSearchMode: widget.isSearchMode,
      logEntriesCount: widget.logEntriesCount,
      onToggleSortOrder: () {
        widget.onToggleSortOrder();
        Navigator.of(context).pop();
      },
      onRefreshLogs: widget.onRefreshLogs != null
          ? () {
              widget.onRefreshLogs!();
              Navigator.of(context).pop();
            }
          : null,
      onCleanupLogs: () {
        Navigator.of(context).pop();
        widget.onCleanupLogs();
      },
      onExportLogs: () {
        Navigator.of(context).pop();
        widget.onExportLogs();
      },
      onClearFilters: () {
        widget.onClearFilters();
        Navigator.of(context).pop();
      },
      onQuickScroll: widget.onQuickScroll != null
          ? () {
              Navigator.of(context).pop();
              widget.onQuickScroll!();
            }
          : null,
    );
  }
}
