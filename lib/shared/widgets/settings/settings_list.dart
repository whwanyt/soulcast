import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 设置分组卡片容器，自动插入分隔线。
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              Divider(height: 1, thickness: 1, indent: 52, color: dividerColor),
          ],
        ],
      ),
    );
  }
}

/// 设置页统一行布局，支持标题、副标题与尾部控件。
class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final VoidCallback onTap;
  final IconData leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(leading, size: 22, color: colorScheme.onSurface),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            trailing ??
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}

/// 在底部面板中选择枚举值的设置行。
class SettingsDropdownTile<T> extends StatefulWidget {
  const SettingsDropdownTile({
    super.key,
    required this.leading,
    required this.title,
    required this.value,
    required this.valueLabel,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
  });

  final IconData leading;
  final String title;
  final T value;
  final String valueLabel;
  final List<T> options;
  final String Function(T option) optionLabel;
  final ValueChanged<T> onSelected;

  @override
  State<SettingsDropdownTile<T>> createState() =>
      _SettingsDropdownTileState<T>();
}

class _SettingsDropdownTileState<T> extends State<SettingsDropdownTile<T>> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(AppSpacing.lg, 0),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
        shadowColor: WidgetStatePropertyAll(
          colorScheme.shadow.withValues(alpha: 0.18),
        ),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
      onOpen: () => setState(() {}),
      onClose: () => setState(() {}),
      menuChildren: [
        for (final option in widget.options)
          MenuItemButton(
            onPressed: () {
              widget.onSelected(option);
              _menuController.close();
            },
            trailingIcon: option == widget.value
                ? Icon(
                    LucideIcons.check,
                    size: 18,
                    color: colorScheme.onSurface,
                  )
                : const SizedBox(width: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160),
              child: Text(
                widget.optionLabel(option),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;

        return SettingsListTile(
          onTap: () {
            if (isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          leading: widget.leading,
          title: widget.title,
          subtitle: widget.valueLabel,
          trailing: Icon(
            isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
