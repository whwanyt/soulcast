part of '../speech_model_settings_page.dart';

enum _SpeechModelAction { download, cancel, setDefault, delete }

class _AddSpeechModelSheet extends ConsumerStatefulWidget {
  const _AddSpeechModelSheet();

  @override
  ConsumerState<_AddSpeechModelSheet> createState() =>
      _AddSpeechModelSheetState();
}

class _AddSpeechModelSheetState extends ConsumerState<_AddSpeechModelSheet> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  var _kind = SpeechModelKind.asr;
  var _submitting = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.speechModelSettings;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.addModel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            translations.kindLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<SpeechModelKind>(
            segments: [
              ButtonSegment(
                value: SpeechModelKind.asr,
                label: Text(
                  translations.kindAsr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment(
                value: SpeechModelKind.tts,
                label: Text(
                  translations.kindTts,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (value) {
              setState(() => _kind = value.first);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _urlController,
            autofocus: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: translations.urlLabel,
              hintText: translations.urlHint,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: translations.nameLabel,
              hintText: translations.nameHint,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(translations.add),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      SmartDialog.showToast(context.t.speechModelSettings.urlRequired);
      return;
    }
    setState(() => _submitting = true);
    try {
      final notifier = ref.read(manageSpeechModelProvider.notifier);
      final model = await notifier.addModel(
        downloadUrl: url,
        displayName: _nameController.text.trim(),
        kind: _kind,
      );
      await notifier.startDownload(model.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        SmartDialog.showToast(
          context.t.speechModelSettings.downloadFailed(error: '$error'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: emphasized
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
