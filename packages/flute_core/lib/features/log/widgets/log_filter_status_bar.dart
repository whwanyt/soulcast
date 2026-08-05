import 'package:flute_core/log/log.dart';
import 'package:flutter/material.dart';
import '../utils/log_utils.dart';

/// 日志筛选状态指示器组件
/// 显示当前的筛选条件状态
class LogFilterStatusBar extends StatelessWidget {
  /// 当前选中的日期
  final DateTime? selectedDate;

  /// 当前级别筛选器
  final Set<LogLevel> levelFilter;

  /// 清除筛选回调
  final VoidCallback onClearFilters;

  /// 构造函数
  const LogFilterStatusBar({
    super.key,
    required this.selectedDate,
    required this.levelFilter,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null && levelFilter.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildFilterStatusText(),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClearFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear, size: 12, color: theme.colorScheme.error),
                  const SizedBox(width: 4),
                  Text(
                    '清除',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建筛选状态文本
  String _buildFilterStatusText() {
    final List<String> filters = [];

    if (selectedDate != null) {
      filters.add('日期: ${LogUtils.formatShortDate(selectedDate!)}');
    }

    if (levelFilter.isNotEmpty) {
      final levelNames = levelFilter
          .map((level) => level.name.toUpperCase())
          .join(', ');
      filters.add('级别: $levelNames');
    }

    return '已应用筛选条件: ${filters.join(' | ')}';
  }

  // 删除 _formatDate 方法
}
