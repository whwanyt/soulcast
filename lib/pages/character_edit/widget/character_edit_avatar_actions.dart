part of '../character_edit_page.dart';

mixin _CharacterEditAvatarActions on _CharacterEditFormState {
  Future<void> _pickLocalAvatar() async {
    final translations = context.t.characterEdit;
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      final path = file?.path;
      if (path == null || path.isEmpty) {
        return;
      }
      await _applyLocalAvatarPath(path);
    } catch (_) {
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(translations.avatarPickFailed);
    }
  }

  Future<void> _pickAvatarFromLibrary() async {
    final translations = context.t.characterEdit;
    final path = await showFileLibraryImagePicker(context);
    if (path == null || path.isEmpty || !mounted) {
      return;
    }
    try {
      await _applyLocalAvatarPath(path);
    } catch (_) {
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(translations.avatarPickFailed);
    }
  }

  Future<void> _applyLocalAvatarPath(String path) async {
    final uri = await ref
        .read(manageCharacterServiceProvider)
        .importLocalAvatar(path);
    if (!mounted) {
      return;
    }
    setState(() => _avatarUrl = uri.toString());
  }

  Future<void> _showAvatarGenerateSheet() async {
    final configs = ref.read(agentToolConfigsProvider);
    final configuredModelId = configs[AgentToolIds.generateImage]
        ?.stringParam(AgentToolIds.imageModelId)
        ?.trim();
    final initialPrompt = buildDefaultAvatarPromptText(
      appearance: _appearanceController.text,
    );

    final avatarUrl = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return CharacterEditAvatarGenerateSheet(
          initialPrompt: initialPrompt,
          initialImageModelId:
              configuredModelId == null || configuredModelId.isEmpty
              ? null
              : configuredModelId,
        );
      },
    );
    if (avatarUrl == null || !mounted) {
      return;
    }
    setState(() => _avatarUrl = avatarUrl);
    SmartDialog.showToast(context.t.characterEdit.avatarGenerated);
  }

  void _clearAvatar() {
    setState(() => _avatarUrl = null);
  }
}
