part of '../character_edit_page.dart';

/// 展示备选开场白管理底部面板，确认后返回最新列表。
Future<List<String>?> showCharacterEditAlternateGreetingsSheet({
  required BuildContext context,
  required List<String> initialGreetings,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return CharacterEditAlternateGreetingsSheet(
        initialGreetings: initialGreetings,
      );
    },
  );
}

/// 展示单条备选开场白编辑底部面板，确认后返回文本。
Future<String?> showCharacterEditAlternateGreetingEditorSheet({
  required BuildContext context,
  required String title,
  String initialText = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return CharacterEditAlternateGreetingEditorSheet(
        title: title,
        initialText: initialText,
      );
    },
  );
}

/// 角色编辑页：管理全部备选开场白。
class CharacterEditAlternateGreetingsSheet extends StatefulWidget {
  const CharacterEditAlternateGreetingsSheet({
    required this.initialGreetings,
    super.key,
  });

  final List<String> initialGreetings;

  @override
  State<CharacterEditAlternateGreetingsSheet> createState() =>
      _CharacterEditAlternateGreetingsSheetState();
}

class _CharacterEditAlternateGreetingsSheetState
    extends State<CharacterEditAlternateGreetingsSheet> {
  late List<String> _greetings;

  @override
  void initState() {
    super.initState();
    _greetings = [...widget.initialGreetings];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = context.t.characterEdit;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.75;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        mediaQuery.viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    translations.manageAlternateGreetings,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: translations.addAlternateGreeting,
                  onPressed: _addGreeting,
                  icon: const Icon(LucideIcons.plus),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _greetings.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        translations.alternateGreetingsEmpty,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _greetings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final text = _greetings[index];
                        return Material(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            title: Text(
                              text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: translations.removeAlternateGreeting,
                              onPressed: () {
                                setState(() => _greetings.removeAt(index));
                              },
                              icon: const Icon(LucideIcons.x),
                            ),
                            onTap: () => _editGreeting(index),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      context.t.common.cancel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_greetings),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      context.t.common.save,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGreeting() async {
    final text = await showCharacterEditAlternateGreetingEditorSheet(
      context: context,
      title: context.t.characterEdit.addAlternateGreeting,
    );
    if (!mounted || text == null) {
      return;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() => _greetings.add(trimmed));
  }

  Future<void> _editGreeting(int index) async {
    final text = await showCharacterEditAlternateGreetingEditorSheet(
      context: context,
      title: context.t.characterEdit.editAlternateGreeting,
      initialText: _greetings[index],
    );
    if (!mounted || text == null) {
      return;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() => _greetings.removeAt(index));
      return;
    }
    setState(() => _greetings[index] = trimmed);
  }
}

/// 角色编辑页：录入/编辑一条备选开场白。
class CharacterEditAlternateGreetingEditorSheet extends StatefulWidget {
  const CharacterEditAlternateGreetingEditorSheet({
    required this.title,
    this.initialText = '',
    super.key,
  });

  final String title;
  final String initialText;

  @override
  State<CharacterEditAlternateGreetingEditorSheet> createState() =>
      _CharacterEditAlternateGreetingEditorSheetState();
}

class _CharacterEditAlternateGreetingEditorSheetState
    extends State<CharacterEditAlternateGreetingEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final translations = context.t.characterEdit;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            labelText: translations.alternateGreetingSheetLabel,
            hintText: translations.alternateGreetingHint,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    context.t.common.cancel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    context.t.common.save,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(_controller.text);
  }
}
