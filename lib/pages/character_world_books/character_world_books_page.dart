import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/world_book/world_book.dart';
import 'package:soulcast/features/manage_character/manage_character.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 角色世界书多本绑定页。
class CharacterWorldBooksPage extends ConsumerWidget {
  const CharacterWorldBooksPage({required this.characterId, super.key});

  final String characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.characterWorldBooks;
    final charactersAsync = ref.watch(charactersProvider);
    final booksAsync = ref.watch(worldBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translations.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: translations.addBook,
            onPressed: () => _addBooks(context, ref),
            icon: const Icon(LucideIcons.plus),
          ),
          IconButton(
            tooltip: translations.openLibrary,
            onPressed: () => const WorldBookSettingsRoute().push(context),
            icon: const Icon(LucideIcons.library),
          ),
        ],
      ),
      body: charactersAsync.when(
        data: (characters) {
          CharacterEntity? character;
          for (final item in characters) {
            if (item.id == characterId) {
              character = item;
              break;
            }
          }
          final current = character;
          if (current == null) {
            return Center(child: Text(translations.notFound));
          }
          final boundIds = current.boundWorldBookIds;
          return booksAsync.when(
            data: (books) {
              final byId = {for (final book in books) book.id: book};
              if (boundIds.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    child: Text(
                      translations.emptyDescription,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  24,
                ),
                itemCount: boundIds.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final id = boundIds[index];
                  final book = byId[id];
                  final isPrimary = current.primaryWorldBookId == id;
                  final title = book?.name ?? id;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      isPrimary
                          ? translations.primaryBadge
                          : translations.extraBadge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<_BindAction>(
                      onSelected: (action) =>
                          _onAction(context, ref, current, id, action),
                      itemBuilder: (context) => [
                        if (!isPrimary)
                          PopupMenuItem(
                            value: _BindAction.setPrimary,
                            child: Text(translations.setPrimary),
                          ),
                        PopupMenuItem(
                          value: _BindAction.edit,
                          child: Text(translations.openEdit),
                        ),
                        PopupMenuItem(
                          value: _BindAction.remove,
                          child: Text(translations.remove),
                        ),
                      ],
                    ),
                    onTap: () =>
                        WorldBookEditRoute(worldBookId: id).push(context),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }

  Future<void> _addBooks(BuildContext context, WidgetRef ref) async {
    final translations = context.t.characterWorldBooks;
    final character = (await ref.read(
      characterRepositoryProvider.future,
    )).getCharacter(characterId);
    if (character == null || !context.mounted) {
      SmartDialog.showToast(translations.notFound);
      return;
    }
    final books = (await ref.read(
      worldBookRepositoryProvider.future,
    )).getWorldBooks();
    final bound = character.boundWorldBookIds.toSet();
    final candidates = books.where((book) => !bound.contains(book.id)).toList();
    if (candidates.isEmpty) {
      SmartDialog.showToast(translations.noAvailableBooks);
      return;
    }
    if (!context.mounted) {
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final book in candidates)
                ListTile(
                  title: Text(
                    book.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(book.id),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) {
      return;
    }
    final primary = character.primaryWorldBookId;
    if (primary == null || primary.isEmpty) {
      await ref
          .read(manageCharacterServiceProvider)
          .setWorldBookBindings(
            characterId: characterId,
            primaryWorldBookId: selected,
            extraWorldBookIds: const [],
          );
    } else {
      await ref
          .read(manageCharacterServiceProvider)
          .setWorldBookBindings(
            characterId: characterId,
            primaryWorldBookId: primary,
            extraWorldBookIds: [...character.extraWorldBookIds, selected],
          );
    }
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    CharacterEntity character,
    String worldBookId,
    _BindAction action,
  ) async {
    switch (action) {
      case _BindAction.setPrimary:
        final extras = [
          if (character.primaryWorldBookId != null &&
              character.primaryWorldBookId != worldBookId)
            character.primaryWorldBookId!,
          ...character.extraWorldBookIds.where((id) => id != worldBookId),
        ];
        await ref
            .read(manageCharacterServiceProvider)
            .setWorldBookBindings(
              characterId: characterId,
              primaryWorldBookId: worldBookId,
              extraWorldBookIds: extras,
            );
      case _BindAction.edit:
        if (context.mounted) {
          await WorldBookEditRoute(worldBookId: worldBookId).push(context);
        }
      case _BindAction.remove:
        final primary = character.primaryWorldBookId == worldBookId
            ? null
            : character.primaryWorldBookId;
        var extras = character.extraWorldBookIds
            .where((id) => id != worldBookId)
            .toList();
        if (primary == null && extras.isNotEmpty) {
          // 移除主书后，第一本 extra 升为 primary。
          await ref
              .read(manageCharacterServiceProvider)
              .setWorldBookBindings(
                characterId: characterId,
                primaryWorldBookId: extras.first,
                extraWorldBookIds: extras.skip(1).toList(),
              );
        } else {
          await ref
              .read(manageCharacterServiceProvider)
              .setWorldBookBindings(
                characterId: characterId,
                primaryWorldBookId: primary,
                extraWorldBookIds: extras,
              );
        }
    }
  }
}

enum _BindAction { setPrimary, edit, remove }
