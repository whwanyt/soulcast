part of '../character_edit_page.dart';

mixin _CharacterEditPersistenceActions on _CharacterEditDraftActions {
  Future<void> _openWorldBook() async {
    final characterId = widget.characterId;
    if (characterId == null) {
      SmartDialog.showToast(context.t.characterEdit.worldBookSaveFirst);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _persistCharacter(characterId: characterId);
      if (!mounted) {
        return;
      }
      await CharacterWorldBooksRoute(characterId: characterId).push(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<CharacterEntity> _persistCharacter({String? characterId}) {
    return ref
        .read(manageCharacterServiceProvider)
        .saveCharacter(
          characterId: characterId ?? widget.characterId,
          name: _nameController.text,
          avatarUrl: _avatarUrl,
          description: _descriptionController.text,
          personality: _personalityController.text,
          speechStyle: _speechStyleController.text,
          appearance: _appearanceController.text,
          scenario: _scenarioController.text,
          greetings: _collectGreetings(),
          exampleDialogues: _exampleDialoguesController.text,
          hardConstraints: _hardConstraintsController.text,
          tags: _collectTags(),
          creatorNotes: _creatorNotesController.text,
          cardSystemPrompt: _cardSystemPromptController.text,
          postHistoryInstructions: _postHistoryInstructionsController.text,
        );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _persistCharacter();
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(context.t.characterEdit.saved);
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteCharacter(String characterId) async {
    final translations = context.t.characterEdit;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            translations.deleteTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(translations.deleteMessage),
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

    setState(() => _isSaving = true);
    try {
      await ref
          .read(manageCharacterServiceProvider)
          .deleteCharacter(characterId);
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(context.t.characterEdit.deleted);
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
