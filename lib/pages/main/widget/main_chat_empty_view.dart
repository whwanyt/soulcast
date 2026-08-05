import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 当前会话没有消息时的主页面引导内容。
class MainChatEmptyView extends StatelessWidget {
  const MainChatEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          96,
          AppSpacing.xxl,
          132,
        ),
        child: Column(
          children: [
            const Spacer(flex: 3),
            SizedBox.square(
              dimension: 72,
              child: Icon(
                LucideIcons.sparkles,
                size: 30,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              context.t.main.empty.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }
}
