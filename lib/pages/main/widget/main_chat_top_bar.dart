import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 主聊天页悬浮顶栏，提供会话抽屉与详情入口。
class MainChatTopBar extends StatelessWidget {
  const MainChatTopBar({
    super.key,
    required this.isInfoEnabled,
    required this.onMenuPressed,
    required this.onInfoPressed,
    this.hideBackgroundGradient = false,
  });

  final bool isInfoEnabled;
  final VoidCallback onMenuPressed;
  final VoidCallback onInfoPressed;

  /// 角色会话时去掉背后的 surface 渐变，让头像背景直接露出。
  final bool hideBackgroundGradient;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surfaceContainerLow;
    final paddingTop = MediaQuery.of(context).padding.top;

    final bar = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        paddingTop + 4,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          AppFloatingIconButton(
            tooltip: context.t.main.menu,
            icon: LucideIcons.menu,
            onPressed: onMenuPressed,
            showShadow: false,
            transparentBackground: hideBackgroundGradient,
          ),
          const Spacer(),
          AppFloatingIconButton(
            tooltip: context.t.main.info.title,
            icon: LucideIcons.info,
            onPressed: isInfoEnabled ? onInfoPressed : null,
            showShadow: false,
            transparentBackground: hideBackgroundGradient,
          ),
        ],
      ),
    );

    if (hideBackgroundGradient) {
      return bar;
    }

    return DecoratedBox(
      key: const ValueKey('main_chat_header_gradient'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            surface,
            surface,
            surface.withValues(alpha: 0.88),
            surface.withValues(alpha: 0.45),
            surface.withValues(alpha: 0),
          ],
          stops: const [0, 0.42, 0.62, 0.82, 1],
        ),
      ),
      child: bar,
    );
  }
}
