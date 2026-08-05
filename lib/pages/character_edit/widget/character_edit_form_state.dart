part of '../character_edit_page.dart';

mixin _CharacterEditFormState on ConsumerState<CharacterEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _personalityController = TextEditingController();
  final _speechStyleController = TextEditingController();
  final _appearanceController = TextEditingController();
  final _scenarioController = TextEditingController();
  final _greetingController = TextEditingController();
  final _exampleDialoguesController = TextEditingController();
  final _hardConstraintsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _cardSystemPromptController = TextEditingController();
  final _postHistoryInstructionsController = TextEditingController();
  final _creatorNotesController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;
  String? _avatarUrl;
  List<String> _alternateGreetings = const [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
    _speechStyleController.dispose();
    _appearanceController.dispose();
    _scenarioController.dispose();
    _greetingController.dispose();
    _exampleDialoguesController.dispose();
    _hardConstraintsController.dispose();
    _tagsController.dispose();
    _cardSystemPromptController.dispose();
    _postHistoryInstructionsController.dispose();
    _creatorNotesController.dispose();
    super.dispose();
  }

  /// 仅在实体首次加载完成时填充表单，避免 provider 刷新覆盖用户输入。
  void _syncFromCharacter(CharacterEntity character) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _nameController.text = character.name;
    _avatarUrl = character.avatarUrl;
    _descriptionController.text = character.description;
    _personalityController.text = character.personality;
    _speechStyleController.text = character.speechStyle;
    _appearanceController.text = character.appearance;
    _scenarioController.text = character.scenario;
    _setGreetings(character.nonEmptyGreetings);
    _exampleDialoguesController.text = character.exampleDialogues;
    _hardConstraintsController.text = character.hardConstraints;
    _tagsController.text = character.tags.join(', ');
    _cardSystemPromptController.text = character.cardSystemPrompt;
    _postHistoryInstructionsController.text = character.postHistoryInstructions;
    _creatorNotesController.text = character.creatorNotes;
  }

  void _setGreetings(List<String> greetings) {
    if (greetings.isEmpty) {
      _greetingController.text = '';
      _alternateGreetings = const [];
      return;
    }
    _greetingController.text = greetings.first;
    _alternateGreetings = greetings.length <= 1
        ? const []
        : List<String>.unmodifiable(greetings.sublist(1));
  }

  List<String> _collectGreetings() {
    final primary = _greetingController.text.trim();
    return [
      if (primary.isNotEmpty) primary,
      ..._alternateGreetings
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
    ];
  }

  String _alternateGreetingsSummary(dynamic translations) {
    if (_alternateGreetings.isEmpty) {
      return translations.alternateGreetingsEmpty as String;
    }
    return translations.alternateGreetingsCount(
          count: _alternateGreetings.length,
        )
        as String;
  }

  List<String> _collectTags() {
    return _tagsController.text
        .split(RegExp(r'[,，]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
