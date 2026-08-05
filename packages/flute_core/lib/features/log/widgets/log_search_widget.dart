import 'package:flutter/material.dart';

/// 日志搜索组件
/// 提供搜索输入和清除功能
class LogSearchWidget extends StatefulWidget {
  /// 搜索回调
  final Function(String) onSearch;

  /// 清除回调
  final VoidCallback onClear;

  /// 构造函数
  /// [onSearch] 搜索回调
  /// [onClear] 清除回调
  const LogSearchWidget({
    super.key,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<LogSearchWidget> createState() => _LogSearchWidgetState();
}

class _LogSearchWidgetState extends State<LogSearchWidget> {
  /// 搜索控制器
  final TextEditingController _searchController = TextEditingController();

  /// 搜索焦点
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: '搜索日志内容或标签...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          widget.onClear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(color: theme.colorScheme.onSurface),
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  widget.onClear();
                }
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onSearch(value.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _searchController.text.trim().isEmpty
                ? null
                : () => widget.onSearch(_searchController.text.trim()),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
}
