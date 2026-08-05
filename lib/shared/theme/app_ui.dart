import 'package:flutter/material.dart';

/// Shared visual tokens for consistent spacing, radius, and elevation.
///
/// Values follow a 4pt grid and Material / HIG mobile defaults.
abstract final class AppRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 28;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Screen / list horizontal inset.
  static const double page = 12;

  /// Comfortable tap target (Material 48dp; covers HIG 44pt).
  static const double floatingControl = 48;
}

abstract final class AppShadows {
  static List<BoxShadow> soft([Color color = Colors.black]) => [
    BoxShadow(
      color: color.withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      blurRadius: 12,
    ),
  ];

  static List<BoxShadow> elevated([Color color = Colors.black]) => [
    BoxShadow(
      color: color.withValues(alpha: 0.08),
      offset: const Offset(0, 6),
      blurRadius: 20,
    ),
  ];

  static List<BoxShadow> input([Color color = Colors.black]) => [
    BoxShadow(
      color: color.withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 16,
    ),
  ];
}

/// Circular floating control used by chat top bar and similar surfaces.
class AppFloatingIconButton extends StatelessWidget {
  const AppFloatingIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = AppSpacing.floatingControl,
    this.iconSize = 22,
    this.showShadow = true,
    this.transparentBackground = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final bool showShadow;

  /// 角色聊天顶栏等场景下去掉圆形底色。
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;
    final iconColor = colorScheme.onSurface;

    final button = Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: isEnabled ? 1 : 0.42,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );

    if (transparentBackground) {
      return Tooltip(message: tooltip, child: button);
    }

    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: showShadow ? AppShadows.soft(colorScheme.shadow) : null,
        ),
        child: button,
      ),
    );
  }
}
