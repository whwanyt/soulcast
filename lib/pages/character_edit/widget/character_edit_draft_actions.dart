part of '../character_edit_page.dart';

mixin _CharacterEditDraftActions on _CharacterEditAvatarActions {
  Future<void> _showAiAssistSheet() async {
    final draft = await showModalBottomSheet<GeneratedCharacterDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return const CharacterEditAiAssistSheet();
      },
    );
    if (draft == null || !mounted) {
      return;
    }

    _applyDraft(draft);
    SmartDialog.showToast(context.t.characterEdit.generated);
  }

  void _applyDraft(GeneratedCharacterDraft draft) {
    setState(() {
      _nameController.text = draft.name;
      _descriptionController.text = draft.description;
      _personalityController.text = draft.personality;
      _speechStyleController.text = draft.speechStyle;
      _appearanceController.text = draft.appearance;
      _scenarioController.text = draft.scenario;
      _setGreetings(draft.greetings);
      _exampleDialoguesController.text = draft.exampleDialogues;
      _hardConstraintsController.text = draft.hardConstraints;
    });
  }

  Future<void> _manageAlternateGreetings(BuildContext context) async {
    final updated = await showCharacterEditAlternateGreetingsSheet(
      context: context,
      initialGreetings: _alternateGreetings,
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _alternateGreetings = List<String>.unmodifiable(
        updated.map((item) => item.trim()).where((item) => item.isNotEmpty),
      );
    });
  }
}
