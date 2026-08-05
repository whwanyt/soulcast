import 'package:flute_core/log/log_level.dart';
import 'package:flutter/material.dart';
import '../models/log_entry.dart';

/// 日志条目显示组件
/// 用于在列表中显示单条日志记录
class LogEntryWidget extends StatelessWidget {
  /// 日志条目数据
  final LogEntry entry;

  /// 点击回调
  final VoidCallback? onTap;

  /// 构造函数
  /// [entry] 日志条目数据
  /// [onTap] 点击回调
  const LogEntryWidget({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: entry.levelColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部信息行
                Row(
                  children: [
                    // 日志级别指示器
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: entry.levelColor,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 日志级别图标和文本
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: entry.levelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: entry.levelColor.withValues(alpha: 0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            entry.levelIcon,
                            color: entry.levelColor,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            entry.level.name.toUpperCase(),
                            style: TextStyle(
                              color: entry.levelColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        entry.tag,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // 时间戳
                    Text(
                      _formatTimestamp(entry.timestamp),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 日志消息
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.message,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 格式化时间戳
  /// [timestamp] 时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (logDate == today) {
      // 今天的日志只显示时间
      return '${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}:'
          '${timestamp.second.toString().padLeft(2, '0')}';
    } else {
      // 其他日期显示完整时间
      return '${timestamp.month.toString().padLeft(2, '0')}-'
          '${timestamp.day.toString().padLeft(2, '0')} '
          '${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 判断是否应该显示完整消息
  /// [entry] 日志条目
  // ignore: unused_element
  bool _shouldShowFullMessage(LogEntry entry) {
    // 错误级别的日志或包含换行符的消息显示完整内容
    return entry.level == LogLevel.error ||
        entry.level == LogLevel.fatal ||
        entry.message.contains('\n') ||
        entry.message.contains('├─') ||
        entry.message.contains('└─');
  }
}
