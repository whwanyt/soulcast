import 'package:flute_core/log/log_level.dart';
import 'package:flutter/material.dart';
import '../utils/log_utils.dart';

/// 日志筛选条件区域组件
/// 提供日期选择和级别筛选功能
class LogFilterSection extends StatelessWidget {
  /// 可用日期列表
  final List<DateTime> availableDates;

  /// 当前选中的日期
  final DateTime? selectedDate;

  /// 当前级别筛选器
  final Set<LogLevel> levelFilter;

  /// 是否为搜索模式
  final bool isSearchMode;

  /// 日期变更回调
  final Function(DateTime?) onDateChanged;

  /// 级别筛选变更回调
  final Function(Set<LogLevel>) onLevelFilterChanged;

  /// 清除全部回调
  final VoidCallback onClearAll;

  /// 构造函数
  const LogFilterSection({
    super.key,
    required this.availableDates,
    required this.selectedDate,
    required this.levelFilter,
    required this.isSearchMode,
    required this.onDateChanged,
    required this.onLevelFilterChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.shadowColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          if (!isSearchMode) ...[
            _buildDateSelector(context),
            const SizedBox(height: 20),
          ],
          _buildLevelFilter(context),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(Icons.filter_alt, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '筛选条件',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        if (selectedDate != null || levelFilter.isNotEmpty) ...[
          GestureDetector(
            onTap: onClearAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear_all, size: 14, color: colorScheme.error),
                  const SizedBox(width: 4),
                  Text(
                    '清除全部',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建日期选择器
  Widget _buildDateSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '选择日期',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DateTime?>(
              value: selectedDate,
              isExpanded: true,
              hint: Text(
                '选择要查看的日期',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              dropdownColor: colorScheme.surface,
              items: availableDates.map((date) {
                return DropdownMenuItem<DateTime?>(
                  value: date,
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: selectedDate == date
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LogUtils.formatDate(date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: selectedDate == date
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: selectedDate == date
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onDateChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建级别筛选器
  Widget _buildLevelFilter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.label, size: 16, color: colorScheme.secondary),
            ),
            const SizedBox(width: 12),
            Text(
              '日志级别',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: LogLevel.values
              .where((level) => level != LogLevel.all && level != LogLevel.off)
              .map((level) {
                final isSelected = levelFilter.contains(level);
                final levelColor = LogUtils.getLevelColor(level);

                return GestureDetector(
                  onTap: () {
                    final newFilter = Set<LogLevel>.from(levelFilter);
                    if (isSelected) {
                      newFilter.remove(level);
                    } else {
                      newFilter.add(level);
                    }
                    onLevelFilterChanged(newFilter);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? levelColor : colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          level.name.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : levelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }
}
