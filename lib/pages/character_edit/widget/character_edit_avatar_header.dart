part of '../character_edit_page.dart';

/// 角色编辑页头像预览与操作区。
class CharacterEditAvatarHeader extends StatelessWidget {
  const CharacterEditAvatarHeader({
    required this.avatarUrl,
    required this.name,
    required this.enabled,
    required this.onPick,
    required this.onPickFromLibrary,
    required this.onGenerate,
    required this.onClear,
    super.key,
  });

  final String? avatarUrl;
  final String name;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onPickFromLibrary;
  final VoidCallback onGenerate;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.characterEdit;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CharacterEditAvatarPreview(
                  avatarUrl: avatarUrl,
                  name: name,
                ),
              ),
              if (onClear != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: IconButton.filledTonal(
                    tooltip: translations.avatarClear,
                    onPressed: enabled ? onClear : null,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(28, 28),
                      fixedSize: const Size(28, 28),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(LucideIcons.x, size: 14),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          translations.avatarLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          translations.avatarHint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? onPick : null,
                icon: const Icon(LucideIcons.imagePlus, size: 18),
                label: Text(
                  translations.avatarPick,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? onPickFromLibrary : null,
                icon: const Icon(LucideIcons.folderOpen, size: 18),
                label: Text(
                  translations.avatarFromLibrary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: enabled ? onGenerate : null,
            icon: const Icon(LucideIcons.sparkles, size: 18),
            label: Text(
              translations.avatarGenerate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

/// 圆形头像预览，支持本地与网络地址。
class CharacterEditAvatarPreview extends StatelessWidget {
  const CharacterEditAvatarPreview({
    required this.avatarUrl,
    required this.name,
    super.key,
  });

  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty
        ? '?'
        : String.fromCharCode(name.trim().runes.first);
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return ClipOval(child: placeholder);
    }

    final localFile = resolveAppImageLocalFile(url);
    final image = localFile != null
        ? Image.file(
            localFile,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => placeholder,
          )
        : Image.network(
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

    return ClipOval(child: image);
  }
}
