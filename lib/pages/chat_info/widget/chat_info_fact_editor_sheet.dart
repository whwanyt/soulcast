part of '../chat_info_page.dart';

/// 新建或编辑一条结构化记忆事实的底部面板。
class _FactEditorSheet extends StatefulWidget {
  const _FactEditorSheet({required this.initialFact});

  final _FactDraft? initialFact;

  @override
  State<_FactEditorSheet> createState() => _FactEditorSheetState();
}

class _FactEditorSheetState extends State<_FactEditorSheet> {
  late ChatMemoryFactCategory _category;
  late final TextEditingController _contentController;
  var _content = '';

  @override
  void initState() {
    super.initState();
    final initialFact = widget.initialFact;
    _category = initialFact?.category ?? ChatMemoryFactCategory.relationship;
    _content = initialFact?.content ?? '';
    _contentController = TextEditingController(text: _content)
      ..addListener(() {
        setState(() => _content = _contentController.text);
      });
  }

  @override
  void dispose() {
    _contentController.dispose();
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
            widget.initialFact == null
                ? translations.addMemory
                : translations.editMemory,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: DropdownButtonFormField<ChatMemoryFactCategory>(
                initialValue: _category,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: colorScheme.surface,
                elevation: 8,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelText: translations.categoryLabel,
                ),
                items: ChatMemoryFactCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      _categoryLabel(context, category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (category) {
                  if (category != null) {
                    setState(() => _category = category);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _contentController,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            labelText: translations.memoryContentLabel,
            hintText: translations.memoryContentHint,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('chat_info_fact_save_button'),
            onPressed: _contentController.text.trim().isEmpty ? null : _save,
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
        ],
      ),
    );
  }

  void _save() {
    final now = DateTime.now();
    final initialFact = widget.initialFact;
    Navigator.of(context).pop(
      _FactDraft(
        id: initialFact?.id ?? createChatMemoryFactId(),
        category: _category,
        content: _contentController.text.trim(),
        createdAt: initialFact?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }
}
