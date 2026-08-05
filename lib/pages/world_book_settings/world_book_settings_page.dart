import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/entities/world_book/world_book.dart';
import 'package:soulcast/features/manage_world_book/manage_world_book.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 设置中的世界书资源库列表。
class WorldBookSettingsPage extends ConsumerWidget {
  const WorldBookSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.worldBookSettings;
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
            tooltip: translations.newBook,
            onPressed: () => const WorldBookEditRoute().push(context),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
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
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                title: Text(
                  book.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  book.description.trim().isEmpty
                      ? translations.noDescription
                      : book.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: translations.delete,
                  onPressed: () => _deleteBook(context, ref, book),
                  icon: Icon(
                    LucideIcons.trash2,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () =>
                    WorldBookEditRoute(worldBookId: book.id).push(context),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('$error', maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  Future<void> _deleteBook(
    BuildContext context,
    WidgetRef ref,
    WorldBookEntity book,
  ) async {
    final translations = context.t.worldBookSettings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            translations.deleteTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(translations.deleteMessage(name: book.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.t.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.t.common.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(manageWorldBookServiceProvider).deleteWorldBook(book.id);
    SmartDialog.showToast(translations.deleted);
  }
}
