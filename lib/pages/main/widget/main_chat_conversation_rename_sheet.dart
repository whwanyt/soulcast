part of 'main_chat_drawer_conversation_list.dart';

class MainChatConversationRenameSheet extends StatefulWidget {
  const MainChatConversationRenameSheet({
    super.key,
    required this.initialTitle,
    required this.onSave,
  });

  final String initialTitle;
  final Future<void> Function(String title) onSave;

  @override
  State<MainChatConversationRenameSheet> createState() =>
      _MainChatConversationRenameSheetState();
}

class _MainChatConversationRenameSheetState
    extends State<MainChatConversationRenameSheet> {
  late final TextEditingController _titleController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final translations = context.t.main.renameConversation;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _titleController,
            autofocus: true,
            maxLength: 48,
            textInputAction: TextInputAction.done,
            enabled: !_isSaving,
            labelText: translations.fieldLabel,
            hintText: translations.fieldHint,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
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
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    translations.save,
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

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(_titleController.text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
