import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/prompt/prompt.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

/// 共享的提示词编辑页，按 [promptId] 加载默认与自定义模板。
class PromptEditPage extends ConsumerStatefulWidget {
  const PromptEditPage({required this.promptId, super.key});

  final String promptId;

  @override
  ConsumerState<PromptEditPage> createState() => _PromptEditPageState();
}

class _PromptEditPageState extends ConsumerState<PromptEditPage> {
  late final TextEditingController _controller;
  bool _isInitialized = false;
  bool _isSaving = false;
  PromptId? _resolvedId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      return;
    }

    _resolvedId = PromptId.tryParse(widget.promptId);
    final id = _resolvedId;
    if (id != null) {
      final custom = ref.read(appPreferencesProvider).customPrompt(id);
      _controller.text = resolvePromptTemplate(
        custom: custom,
        defaultTemplate: defaultPromptTemplate(context.t, id),
      );
    }
    _isInitialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final id = _resolvedId;

    if (id == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            translations.prompts.editTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: const Center(child: Text('Unknown prompt')),
      );
    }

    final tokens = supportedTokensFor(id);
    final defaultPrompt = defaultPromptTemplate(translations, id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          promptListTitle(translations, id),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: translations.prompts.save,
            onPressed: _isSaving ? null : () => _savePrompt(id, defaultPrompt),
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppTextField(
              controller: _controller,
              minLines: 8,
              maxLines: 20,
              textInputAction: TextInputAction.newline,
              labelText: translations.prompts.fieldLabel,
              hintText: translations.prompts.fieldHint,
            ),
            const SizedBox(height: 16),
            _PromptTokensPanel(tokens: tokens, onInsert: _insertToken),
            const SizedBox(height: 16),
            _PromptDefaultPanel(
              defaultPrompt: defaultPrompt,
              onRestoreDefault: _isSaving
                  ? null
                  : () => _restoreDefault(id, defaultPrompt),
            ),
          ],
        ),
      ),
    );
  }

  void _insertToken(String tokenName) {
    final token = formatPromptToken(tokenName);
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final next = text.replaceRange(start, end, token);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  Future<void> _savePrompt(PromptId id, String defaultPrompt) async {
    setState(() {
      _isSaving = true;
    });

    final inputPrompt = _controller.text.trim();
    final customPrompt =
        inputPrompt.isEmpty || inputPrompt == defaultPrompt.trim()
        ? null
        : inputPrompt;
    await ref
        .read(appPreferencesProvider.notifier)
        .saveCustomPrompt(id, customPrompt);

    if (!mounted) {
      return;
    }

    if (customPrompt == null) {
      _controller.text = defaultPrompt;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = false;
    });
    SmartDialog.showToast(context.t.prompts.saved);
  }

  Future<void> _restoreDefault(PromptId id, String defaultPrompt) async {
    setState(() {
      _isSaving = true;
    });

    await ref.read(appPreferencesProvider.notifier).saveCustomPrompt(id, null);

    if (!mounted) {
      return;
    }

    _controller.text = defaultPrompt;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = false;
    });
    SmartDialog.showToast(context.t.prompts.defaultRestored);
  }
}

class _PromptTokensPanel extends StatelessWidget {
  const _PromptTokensPanel({required this.tokens, required this.onInsert});

  final List<String> tokens;
  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              translations.prompts.tokensTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (tokens.isEmpty)
              Text(
                translations.prompts.tokensEmpty,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final token in tokens)
                    ActionChip(
                      label: Text(
                        formatPromptToken(token),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      tooltip: promptTokenDescription(translations, token),
                      onPressed: () => onInsert(token),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PromptDefaultPanel extends StatelessWidget {
  const _PromptDefaultPanel({
    required this.defaultPrompt,
    required this.onRestoreDefault,
  });

  final String defaultPrompt;
  final VoidCallback? onRestoreDefault;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_fix_high_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    translations.prompts.defaultTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              defaultPrompt,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onRestoreDefault,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(
                  translations.prompts.restoreDefault,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
