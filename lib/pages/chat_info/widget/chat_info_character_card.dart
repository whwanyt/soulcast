part of '../chat_info_page.dart';

/// 角色会话在 Tab 上方展示的横向角色卡片。
class ChatInfoCharacterCard extends StatelessWidget {
  const ChatInfoCharacterCard({
    required this.character,
    required this.onEdit,
    super.key,
  });

  final CharacterEntity character;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = character.description.trim().isEmpty
        ? context.t.characterManagement.noDescription
        : character.description.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 56,
              child: ChatInfoCharacterAvatar(
                avatarUrl: character.avatarUrl,
                name: character.name,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.t.main.info.editCharacter,
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              icon: Icon(
                LucideIcons.penLine,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 会话信息页角色卡片头像，含占位与错误态。
class ChatInfoCharacterAvatar extends StatelessWidget {
  const ChatInfoCharacterAvatar({
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
    final placeholder = ColoredBox(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: placeholder,
      );
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: image,
    );
  }
}
