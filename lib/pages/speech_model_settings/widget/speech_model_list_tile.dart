part of '../speech_model_settings_page.dart';

class _SpeechModelListTile extends ConsumerWidget {
  const _SpeechModelListTile({required this.model, required this.progress});

  final SpeechModelEntity model;
  final double progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = context.t.speechModelSettings;
    final status = model.modelStatus;
    final isBusy =
        status == SpeechModelStatus.queued ||
        status == SpeechModelStatus.downloading ||
        status == SpeechModelStatus.extracting;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              model.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _KindBadge(
                            label: model.modelKind == SpeechModelKind.tts
                                ? translations.kindTts
                                : translations.kindAsr,
                          ),
                          if (model.isDefault) ...[
                            const SizedBox(width: 8),
                            _KindBadge(
                              label: translations.defaultBadge,
                              emphasized: true,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.downloadUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusText(context.t, status, progress),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: status == SpeechModelStatus.failed
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_SpeechModelAction>(
                  onSelected: (action) => _handleAction(context, ref, action),
                  itemBuilder: (context) => [
                    if (!isBusy && status != SpeechModelStatus.ready)
                      PopupMenuItem(
                        value: _SpeechModelAction.download,
                        child: Text(translations.download),
                      ),
                    if (isBusy)
                      PopupMenuItem(
                        value: _SpeechModelAction.cancel,
                        child: Text(translations.cancelDownload),
                      ),
                    if (status == SpeechModelStatus.ready && !model.isDefault)
                      PopupMenuItem(
                        value: _SpeechModelAction.setDefault,
                        child: Text(translations.setDefault),
                      ),
                    PopupMenuItem(
                      value: _SpeechModelAction.delete,
                      child: Text(translations.delete),
                    ),
                  ],
                ),
              ],
            ),
            if (status == SpeechModelStatus.downloading ||
                status == SpeechModelStatus.queued) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: status == SpeechModelStatus.downloading
                    ? progress.clamp(0, 1)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText(
    Translations translations,
    SpeechModelStatus status,
    double progress,
  ) {
    final t = translations.speechModelSettings;
    return switch (status) {
      SpeechModelStatus.idle => t.statusIdle,
      SpeechModelStatus.queued => t.statusQueued,
      SpeechModelStatus.downloading => t.statusDownloading(
        progress: (progress * 100).round(),
      ),
      SpeechModelStatus.extracting => t.statusExtracting,
      SpeechModelStatus.ready => t.statusReady,
      SpeechModelStatus.failed => t.statusFailed(error: model.errorMessage),
    };
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _SpeechModelAction action,
  ) async {
    final notifier = ref.read(manageSpeechModelProvider.notifier);
    final translations = context.t.speechModelSettings;
    try {
      switch (action) {
        case _SpeechModelAction.download:
          await notifier.startDownload(model.id);
        case _SpeechModelAction.cancel:
          await notifier.cancelDownload(model.id);
        case _SpeechModelAction.setDefault:
          await notifier.setDefault(model.id);
        case _SpeechModelAction.delete:
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(translations.deleteConfirmTitle),
              content: Text(translations.deleteConfirmMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(context.t.common.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(translations.delete),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await notifier.deleteModel(model.id);
          }
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = action == _SpeechModelAction.setDefault
          ? translations.setDefaultFailed
          : translations.downloadFailed(error: error.toString());
      SmartDialog.showToast(message);
    }
  }
}
