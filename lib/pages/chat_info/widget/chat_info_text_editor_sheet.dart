part of '../chat_info_page.dart';

/// 编辑摘要或会话系统提示词的通用文本底部面板。
class _TextEditorSheet extends StatefulWidget {
  const _TextEditorSheet({
    required this.title,
    required this.labelText,
    required this.hintText,
    required this.initialText,
    this.fallbackText,
    required this.minLines,
    required this.maxLines,
  });

  final String title;
  final String labelText;
  final String hintText;
  final String initialText;
  final String? fallbackText;
  final int minLines;
  final int maxLines;

  @override
  State<_TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<_TextEditorSheet> {
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
    final translations = context.t.main.info;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
          if (widget.fallbackText != null) ...[
            const SizedBox(height: 8),
            Text(
              translations.systemPromptFallbackHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppTextField(
            controller: _controller,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            textInputAction: TextInputAction.newline,
            labelText: widget.labelText,
            hintText: widget.hintText,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.fallbackText != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _restoreDefault,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(LucideIcons.rotateCcw),
                    label: Text(
                      translations.useAppSystemPrompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('chat_info_text_save_button'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(LucideIcons.save),
                  label: Text(
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

  void _restoreDefault() {
    Navigator.of(context).pop('');
  }

  void _save() {
    Navigator.of(context).pop(_controller.text.trim());
  }
}
