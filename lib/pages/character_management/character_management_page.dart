import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/manage_character/manage_character.dart';
import 'package:soulcast/features/manage_world_book/manage_world_book.dart';
import 'package:soulcast/features/transfer_character/transfer_character.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';

import 'provider/character_management_filter_provider.dart';

part 'widget/character_management_filters.dart';
part 'widget/character_management_card.dart';
part 'widget/character_management_states.dart';
part 'widget/character_management_search_bar.dart';
part 'widget/character_management_chat_actions.dart';
part 'widget/character_management_menu_actions.dart';

/// 角色卡浏览、筛选与管理页面。
class CharacterManagementPage extends ConsumerStatefulWidget {
  const CharacterManagementPage({super.key});

  @override
  ConsumerState<CharacterManagementPage> createState() =>
      _CharacterManagementPageState();
}

class _CharacterManagementPageState
    extends ConsumerState<CharacterManagementPage>
    with _CharacterManagementChatActions, _CharacterManagementMenuActions {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedFilter = ref.watch(
      characterManagementFilterControllerProvider,
    );
    final charactersAsync = ref.watch(charactersProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        title: Text(
          context.t.characterManagement.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: context.t.characterManagement.importCharacter,
            onPressed: _importCharacterCard,
            icon: const Icon(LucideIcons.import),
          ),
          IconButton(
            tooltip: context.t.characterManagement.newCharacter,
            onPressed: () => const CharacterEditRoute().push(context),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: CharacterManagementFilterBar(
                      selectedFilter: selectedFilter,
                      onSelected: ref
                          .read(
                            characterManagementFilterControllerProvider
                                .notifier,
                          )
                          .select,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ..._buildContentSlivers(
                  context,
                  charactersAsync,
                  selectedFilter,
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 96 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 36,
            right: 36,
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            child: CharacterManagementSearchBar(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    AsyncValue<List<CharacterEntity>> charactersAsync,
    CharacterManagementFilter filter,
  ) {
    return [
      charactersAsync.when(
        data: (characters) {
          final visible = _filterCharacters(characters, filter, _searchQuery);
          if (visible.isEmpty) {
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              sliver: const SliverToBoxAdapter(
                child: CharacterManagementEmptyCard(),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final character = visible[index];
                return CharacterManagementCard(
                  character: character,
                  onTap: () => _startChat(character),
                  onMenu: () => _showCharacterMenu(character),
                );
              }, childCount: visible.length),
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, stackTrace) => SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _importCharacterCard() async {
    final translations = context.t.characterManagement;
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json', 'png'],
      );
      final path = file?.path;
      if (path == null || path.isEmpty) {
        return;
      }
      final character = await ref
          .read(characterTransferServiceProvider)
          .importFromFile(
            path: path,
            manageCharacter: ref.read(manageCharacterServiceProvider),
            manageWorldBook: ref.read(manageWorldBookServiceProvider),
          );
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(translations.importSuccess(name: character.name));
    } catch (_) {
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(translations.importFailed);
    }
  }
}
