part of '../character_management_page.dart';

class CharacterManagementCard extends StatelessWidget {
  const CharacterManagementCard({
    required this.character,
    required this.onTap,
    required this.onMenu,
    super.key,
  });

  final CharacterEntity character;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenu,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CharacterAvatar(
              avatarUrl: character.avatarUrl,
              name: character.name,
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                character.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (character.isFavorite) ...[
                    const CharacterManagementCardActionChip(
                      child: Icon(
                        LucideIcons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  CharacterManagementCardActionChip(
                    onTap: onMenu,
                    tooltip: context.t.common.more,
                    child: const Icon(
                      LucideIcons.ellipsisVertical,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 卡片右上角半透明圆形操作底，保证图标在头像上可读。
class CharacterManagementCardActionChip extends StatelessWidget {
  const CharacterManagementCardActionChip({
    required this.child,
    this.onTap,
    this.tooltip,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(dimension: 32, child: Center(child: child)),
      ),
    );

    final label = tooltip?.trim();
    if (label == null || label.isEmpty) {
      return chip;
    }
    return Tooltip(message: label, child: chip);
  }
}

/// 带占位和错误状态的角色头像，铺满父容器。
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    required this.avatarUrl,
    required this.name,
    super.key,
  });

  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          LucideIcons.userRound,
          size: 40,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return placeholder;
    }

    final localFile = resolveAppImageLocalFile(url);
    if (localFile != null) {
      return Image.file(
        localFile,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return placeholder;
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

/// 角色列表为空时的引导卡片。
