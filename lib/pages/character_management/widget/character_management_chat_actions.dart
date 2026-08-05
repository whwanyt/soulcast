part of '../character_management_page.dart';

mixin _CharacterManagementChatActions
    on ConsumerState<CharacterManagementPage> {
  Future<void> _startChat(CharacterEntity character) async {
    final greetings = character.nonEmptyGreetings;
    String? selectedGreeting;
    if (greetings.length > 1) {
      selectedGreeting = await _pickGreeting(character);
      if (selectedGreeting == null) {
        return;
      }
    } else if (greetings.length == 1) {
      selectedGreeting = greetings.first;
    }

    await ref
        .read(chatProvider.notifier)
        .startConversationForCharacter(
          character.id,
          greeting: selectedGreeting,
        );
    if (!mounted) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<String?> _pickGreeting(CharacterEntity character) {
    final translations = context.t.characterManagement;
    final greetings = character.nonEmptyGreetings;
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  8,
                  AppSpacing.page,
                  4,
                ),
                child: Text(
                  translations.selectGreetingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  8,
                ),
                child: Text(
                  translations.selectGreetingSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
              ),
              for (var i = 0; i < greetings.length; i++)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                  ),
                  title: Text(
                    translations.greetingOption(index: i + 1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    greetings[i],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(greetings[i]),
                ),
            ],
          ),
        );
      },
    );
  }
}
