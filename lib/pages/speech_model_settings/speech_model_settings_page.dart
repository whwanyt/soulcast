import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';
import 'package:soulcast/features/manage_speech_model/manage_speech_model.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

part 'widget/speech_model_empty_view.dart';
part 'widget/speech_model_list_tile.dart';
part 'widget/speech_model_add_sheet.dart';

/// ASR/TTS 模型下载、安装与默认项管理页面。
class SpeechModelSettingsPage extends ConsumerWidget {
  const SpeechModelSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(speechModelsProvider);
    final progressById = ref.watch(speechModelDownloadProgressProvider);
    // 确保下载管理器已初始化。
    ref.watch(manageSpeechModelProvider);
    final translations = context.t.speechModelSettings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translations.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: translations.addModel,
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: SafeArea(
        child: modelsAsync.when(
          data: (models) {
            if (models.isEmpty) {
              return _SpeechModelEmptyView(
                onAdd: () => _showAddSheet(context, ref),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: models.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final model = models[index];
                return _SpeechModelListTile(
                  model: model,
                  progress: progressById[model.id] ?? 0,
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _AddSpeechModelSheet(),
    );
    if (added == true && context.mounted) {
      SmartDialog.showToast(context.t.speechModelSettings.added);
    }
  }
}
