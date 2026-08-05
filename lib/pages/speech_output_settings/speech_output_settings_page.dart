import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:soulcast/entities/speech_model/speech_model.dart';
import 'package:soulcast/features/speech/speech.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/model/app_preferences_entity.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

part 'widget/speech_output_speaker_stepper.dart';
part 'widget/speech_output_speaker_picker_sheet.dart';

/// TTS 说话人、语速与参考音频设置页面。
class SpeechOutputSettingsPage extends ConsumerWidget {
  const SpeechOutputSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.speechOutputSettings;
    final speakerId = ref.watch(
      appPreferencesProvider.select((s) => s.ttsSpeakerId),
    );
    final speed = ref.watch(appPreferencesProvider.select((s) => s.ttsSpeed));
    final referencePath = ref.watch(
      appPreferencesProvider.select((s) => s.ttsReferenceAudioPath),
    );
    final defaultTts = ref.watch(defaultTtsSpeechModelProvider);
    final catalogAsync = ref.watch(ttsSpeakerCatalogProvider);
    final bundled = defaultTts == null || defaultTts.localDir.isEmpty
        ? const <String>[]
        : listBundledTtsReferenceAudio(defaultTts.localDir);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              t.speakerSection,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              t.speakerHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Card(
              child: catalogAsync.when(
                loading: () => ListTile(
                  leading: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text(
                    t.speakerLoading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                error: (_, _) => _SpeakerIdStepper(
                  speakerId: speakerId,
                  onChanged: (id) => ref
                      .read(appPreferencesProvider.notifier)
                      .saveTtsSpeakerId(id),
                ),
                data: (speakers) {
                  if (speakers.isEmpty) {
                    return _SpeakerIdStepper(
                      speakerId: speakerId,
                      onChanged: (id) => ref
                          .read(appPreferencesProvider.notifier)
                          .saveTtsSpeakerId(id),
                    );
                  }
                  final current = _findSpeaker(speakers, speakerId);
                  return ListTile(
                    leading: const Icon(LucideIcons.userRound),
                    title: Text(
                      _speakerLabel(context, current, speakerId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      t.speakerPick,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => _openSpeakerPicker(
                      context,
                      ref,
                      speakers: speakers,
                      selectedSid: speakerId,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            Text(
              t.speedSection,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              t.speedHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.speedValue(value: speed.toStringAsFixed(1)),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Slider(
                      value: speed.clamp(minTtsSpeed, maxTtsSpeed),
                      min: minTtsSpeed,
                      max: maxTtsSpeed,
                      divisions: ((maxTtsSpeed - minTtsSpeed) / ttsSpeedStep)
                          .round(),
                      label: speed.toStringAsFixed(1),
                      onChanged: (value) => ref
                          .read(appPreferencesProvider.notifier)
                          .saveTtsSpeed(value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              t.referenceSection,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              t.referenceHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (defaultTts == null)
              Text(t.noDefaultTts, maxLines: 3, overflow: TextOverflow.ellipsis)
            else ...[
              Text(
                t.currentPath(
                  path: referencePath?.isNotEmpty == true
                      ? referencePath!
                      : t.bundledDefault,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (bundled.isEmpty)
                Text(
                  t.noBundledWav,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              else
                ...bundled.map((path) {
                  final selected = referencePath == path;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      leading: Icon(
                        selected
                            ? LucideIcons.circleCheck
                            : LucideIcons.audioLines,
                      ),
                      title: Text(
                        p.basename(path),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => ref
                          .read(appPreferencesProvider.notifier)
                          .saveTtsReferenceAudioPath(path),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _importReference(context, ref),
                    icon: const Icon(LucideIcons.fileUp),
                    label: Text(t.importWav),
                  ),
                  OutlinedButton.icon(
                    onPressed: referencePath == null
                        ? null
                        : () => ref
                              .read(appPreferencesProvider.notifier)
                              .saveTtsReferenceAudioPath(null),
                    icon: const Icon(LucideIcons.eraser),
                    label: Text(t.clearCustom),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  TtsSpeaker? _findSpeaker(List<TtsSpeaker> speakers, int sid) {
    for (final speaker in speakers) {
      if (speaker.sid == sid) {
        return speaker;
      }
    }
    return null;
  }

  String _speakerLabel(BuildContext context, TtsSpeaker? speaker, int sid) {
    final t = context.t.speechOutputSettings;
    if (speaker != null && speaker.hasName) {
      return t.speakerNamedValue(name: speaker.name, id: speaker.sid);
    }
    if (speaker != null) {
      return t.speakerUnnamed(id: speaker.sid);
    }
    return t.speakerUnnamed(id: sid);
  }

  Future<void> _openSpeakerPicker(
    BuildContext context,
    WidgetRef ref, {
    required List<TtsSpeaker> speakers,
    required int selectedSid,
  }) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SpeechOutputSpeakerPickerSheet(
          speakers: speakers,
          selectedSid: selectedSid,
        );
      },
    );
    if (picked == null || !context.mounted) {
      return;
    }
    await ref.read(appPreferencesProvider.notifier).saveTtsSpeakerId(picked);
  }

  Future<void> _importReference(BuildContext context, WidgetRef ref) async {
    final t = context.t.speechOutputSettings;
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['wav'],
      );
      final path = file?.path;
      if (path == null || path.isEmpty) {
        return;
      }
      final imported = await importTtsReferenceAudio(File(path));
      await ref
          .read(appPreferencesProvider.notifier)
          .saveTtsReferenceAudioPath(imported);
      SmartDialog.showToast(t.importSuccess);
    } catch (error) {
      SmartDialog.showToast(t.importFailed(error: '$error'));
    }
  }
}
