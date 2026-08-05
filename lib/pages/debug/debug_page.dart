import 'package:flutter/material.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:flute_core/features/log/log_page.dart';

/// 调试工具入口页。
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  /// 构建调试页主界面。
  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translations.debug.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DebugInfoCard(description: translations.debug.description),
            const SizedBox(height: 8),
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LogPage()),
                ),
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(
                  translations.debug.logViewer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  translations.debug.logViewerSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 调试页用途说明卡片。
class DebugInfoCard extends StatelessWidget {
  const DebugInfoCard({required this.description, super.key});

  final String description;

  /// 构建调试说明卡片。
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bug_report_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
