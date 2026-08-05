import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/features/agent_tools/agent_tools.dart';
import 'package:soulcast/features/browse_file_library/browse_file_library.dart';
import 'package:soulcast/features/manage_character/manage_character.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/prompt/prompt.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

part 'widget/character_edit_helpers.dart';
part 'widget/character_edit_avatar_header.dart';
part 'widget/character_edit_layout.dart';
part 'widget/character_edit_avatar_generate_sheet.dart';
part 'widget/character_edit_ai_assist_sheet.dart';
part 'widget/character_edit_alternate_greeting_sheet.dart';
part 'widget/character_edit_form_state.dart';
part 'widget/character_edit_avatar_actions.dart';
part 'widget/character_edit_draft_actions.dart';
part 'widget/character_edit_persistence_actions.dart';

/// 新建或编辑角色卡的表单页面。
class CharacterEditPage extends ConsumerStatefulWidget {
  const CharacterEditPage({required this.characterId, super.key});

  /// 待编辑角色 id；为空时进入新建模式。
  final String? characterId;

  @override
  ConsumerState<CharacterEditPage> createState() => _CharacterEditPageState();
}

class _CharacterEditPageState extends ConsumerState<CharacterEditPage>
    with
        _CharacterEditFormState,
        _CharacterEditAvatarActions,
        _CharacterEditDraftActions,
        _CharacterEditPersistenceActions {
  @override
  Widget build(BuildContext context) {
    final translations = context.t.characterEdit;
    final characterId = widget.characterId;
    final isEditing = characterId != null;

    if (isEditing) {
      final charactersAsync = ref.watch(charactersProvider);
      charactersAsync.whenData((characters) {
        final character = _findCharacter(characters, characterId);
        if (character != null) {
          _syncFromCharacter(character);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? translations.editTitle : translations.createTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!isEditing)
            IconButton(
              tooltip: translations.aiAssistTitle,
              onPressed: _isSaving ? null : _showAiAssistSheet,
              icon: const Icon(LucideIcons.sparkles),
            ),
          if (isEditing)
            IconButton(
              tooltip: translations.delete,
              onPressed: _isSaving ? null : () => _deleteCharacter(characterId),
              icon: const Icon(LucideIcons.trash2),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSaving) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  CharacterEditAvatarHeader(
                    avatarUrl: _avatarUrl,
                    name: _nameController.text,
                    enabled: !_isSaving,
                    onPick: _pickLocalAvatar,
                    onPickFromLibrary: _pickAvatarFromLibrary,
                    onGenerate: _showAvatarGenerateSheet,
                    onClear: _avatarUrl == null || _avatarUrl!.trim().isEmpty
                        ? null
                        : _clearAvatar,
                  ),
                  const SizedBox(height: 28),
                  CharacterEditSection(
                    title: translations.sectionBasic,
                    children: [
                      AppTextField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        maxLength: 40,
                        textInputAction: TextInputAction.next,
                        labelText: translations.nameLabel,
                        hintText: translations.nameHint,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return translations.nameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _descriptionController,
                        enabled: !_isSaving,
                        minLines: 2,
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.descriptionLabel,
                        hintText: translations.descriptionHint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  CharacterEditSection(
                    title: translations.sectionPersona,
                    children: [
                      AppTextField(
                        controller: _personalityController,
                        enabled: !_isSaving,
                        minLines: 3,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.personalityLabel,
                        hintText: translations.personalityHint,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _speechStyleController,
                        enabled: !_isSaving,
                        minLines: 2,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.speechStyleLabel,
                        hintText: translations.speechStyleHint,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _appearanceController,
                        enabled: !_isSaving,
                        minLines: 2,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.appearanceLabel,
                        hintText: translations.appearanceHint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  CharacterEditSection(
                    title: translations.sectionScene,
                    children: [
                      AppTextField(
                        controller: _scenarioController,
                        enabled: !_isSaving,
                        minLines: 2,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.scenarioLabel,
                        hintText: translations.scenarioHint,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _greetingController,
                        enabled: !_isSaving,
                        minLines: 2,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.greetingLabel,
                        hintText: translations.greetingHint,
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          enabled: !_isSaving,
                          leading: const Icon(LucideIcons.messagesSquare),
                          title: Text(
                            translations.manageAlternateGreetings,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _alternateGreetings.isEmpty
                                ? translations.alternateGreetingsManageHint
                                : _alternateGreetingsSummary(translations),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(LucideIcons.chevronRight),
                          onTap: _isSaving
                              ? null
                              : () => _manageAlternateGreetings(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _exampleDialoguesController,
                        enabled: !_isSaving,
                        minLines: 3,
                        maxLines: 8,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.exampleDialoguesLabel,
                        hintText: translations.exampleDialoguesHint,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _hardConstraintsController,
                        enabled: !_isSaving,
                        minLines: 2,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.hardConstraintsLabel,
                        hintText: translations.hardConstraintsHint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  CharacterEditSection(
                    title: translations.sectionCardMeta,
                    children: [
                      AppTextField(
                        controller: _tagsController,
                        enabled: !_isSaving,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        labelText: translations.tagsLabel,
                        hintText: translations.tagsHint,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _cardSystemPromptController,
                        enabled: !_isSaving,
                        minLines: 2,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.cardSystemPromptLabel,
                        hintText: translations.cardSystemPromptHint,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _postHistoryInstructionsController,
                        enabled: !_isSaving,
                        minLines: 2,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.postHistoryInstructionsLabel,
                        hintText: translations.postHistoryInstructionsHint,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _creatorNotesController,
                        enabled: !_isSaving,
                        minLines: 2,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        labelText: translations.creatorNotesLabel,
                        hintText: translations.creatorNotesHint,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.bookOpen),
                        title: Text(
                          translations.worldBook,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          translations.worldBookSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(LucideIcons.chevronRight),
                        onTap: _isSaving ? null : _openWorldBook,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          CharacterEditBottomBar(
            enabled: !_isSaving,
            label: translations.save,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
