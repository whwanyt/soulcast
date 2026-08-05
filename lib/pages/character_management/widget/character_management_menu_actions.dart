part of '../character_management_page.dart';

mixin _CharacterManagementMenuActions on _CharacterManagementChatActions {
  Future<void> _showCharacterMenu(CharacterEntity character) async {
    final translations = context.t.characterManagement;
    final action = await showModalBottomSheet<_CharacterMenuAction>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                leading: const Icon(LucideIcons.messageSquarePlus),
                title: Text(
                  translations.startChat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_CharacterMenuAction.chat),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                leading: const Icon(LucideIcons.penLine),
                title: Text(
                  translations.edit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_CharacterMenuAction.edit),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                leading: Icon(
                  character.isFavorite ? LucideIcons.starOff : LucideIcons.star,
                ),
                title: Text(
                  character.isFavorite
                      ? translations.unfavorite
                      : translations.favorite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_CharacterMenuAction.toggleFavorite),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                leading: Icon(
                  LucideIcons.trash2,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  translations.delete,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_CharacterMenuAction.delete),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }

    switch (action) {
      case _CharacterMenuAction.chat:
        await _startChat(character);
      case _CharacterMenuAction.edit:
        CharacterEditRoute(characterId: character.id).push(context);
      case _CharacterMenuAction.toggleFavorite:
        await ref
            .read(manageCharacterServiceProvider)
            .setFavorite(
              characterId: character.id,
              isFavorite: !character.isFavorite,
            );
      case _CharacterMenuAction.delete:
        await _deleteCharacter(character);
      case null:
        break;
    }
  }

  Future<void> _deleteCharacter(CharacterEntity character) async {
    final translations = context.t.characterManagement;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            translations.deleteTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(translations.deleteMessage(name: character.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                context.t.common.cancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                context.t.common.delete,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await ref
        .read(manageCharacterServiceProvider)
        .deleteCharacter(character.id);
    if (!mounted) {
      return;
    }
    SmartDialog.showToast(translations.deleted);
  }
}
