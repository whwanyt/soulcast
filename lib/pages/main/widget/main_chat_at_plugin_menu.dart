import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 输入 `@` 时浮在输入框上方的插件菜单（当前仅「创建图片」）。
class MainChatAtPluginMenu extends StatelessWidget {
  const MainChatAtPluginMenu({super.key, required this.onCreateImageSelected});

  final VoidCallback onCreateImageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 6,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  context.t.main.input.pluginMenuTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onCreateImageSelected,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Ink(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.72,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.image,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.t.main.input.createImagePlugin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
