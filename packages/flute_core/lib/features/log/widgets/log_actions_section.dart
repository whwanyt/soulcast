import 'package:flutter/material.dart';

/// 日志操作功能区域组件
/// 提供各种日志操作功能
class LogActionsSection extends StatelessWidget {
  /// 是否为正序排列
  final bool isAscendingOrder;

  /// 是否为搜索模式
  final bool isSearchMode;

  /// 日志条目数量
  final int logEntriesCount;

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

  /// 构造函数
  const LogActionsSection({
    super.key,
    required this.isAscendingOrder,
    required this.isSearchMode,
    required this.logEntriesCount,
    required this.onToggleSortOrder,
    required this.onRefreshLogs,
    required this.onCleanupLogs,
    required this.onExportLogs,
    required this.onClearFilters,
    required this.onQuickScroll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildActionButtons(context),
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
        Icon(Icons.settings, size: 20, color: colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          '操作功能',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // 第一行按钮
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: isAscendingOrder
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                label: isAscendingOrder ? '正序排列' : '倒序排列',
                subtitle: isAscendingOrder ? '早→晚' : '晚→早',
                onPressed: onToggleSortOrder,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.refresh,
                label: '刷新日志',
                subtitle: '重新加载',
                onPressed: onRefreshLogs,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 第二行按钮
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.cleaning_services,
                label: '清理日志',
                subtitle: '删除过期',
                onPressed: onCleanupLogs,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.download,
                label: '导出日志',
                subtitle: '保存文件',
                onPressed: onExportLogs,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 第三行按钮
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.clear_all,
                label: '清除筛选',
                subtitle: '重置条件',
                onPressed: onClearFilters,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: isAscendingOrder
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                label: '快速滚动',
                subtitle: isAscendingOrder ? '到底部' : '到顶部',
                onPressed: onQuickScroll,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建单个操作按钮
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = onPressed != null;

    return Material(
      // color: isEnabled
      //     ? color.withValues(alpha: 0.1)
      //     : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      // elevation: isEnabled ? 2 : 0,
      // shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        // splashColor: color.withValues(alpha: 0.2),
        // highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // border: Border.all(
            //   color: isEnabled
            //       ? color.withValues(alpha: 0.3)
            //       : colorScheme.outline.withValues(alpha: 0.2),
            //   width: 1,
            // ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isEnabled
                    ? color
                    : colorScheme.onSurface.withValues(alpha: 0.4),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? color
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isEnabled
                      ? color.withValues(alpha: 0.7)
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
