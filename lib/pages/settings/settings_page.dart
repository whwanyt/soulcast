import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/settings/widget/settings_user_nickname_sheet.dart';
import 'package:soulcast/shared/model/app_preferences_entity.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/settings/settings.dart';

part 'widget/settings_navigation_tiles.dart';
part 'widget/settings_preference_tiles.dart';
part 'widget/settings_page_common.dart';

/// 应用设置入口页，组合通用、AI、聊天、语音、存储与调试选项。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        title: Text(
          translations.settings.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            SettingsSectionTitle(title: translations.settings.general),
            const SizedBox(height: AppSpacing.sm),
            const SettingsGroup(
              children: [SettingsThemeModeSelector(), SettingsLanguageTile()],
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionTitle(title: translations.settings.user),
            const SizedBox(height: AppSpacing.sm),
            const SettingsGroup(children: [SettingsUserNicknameTile()]),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionTitle(title: translations.settings.ai),
            const SizedBox(height: AppSpacing.sm),
            const SettingsGroup(
              children: [
                SettingsProviderTile(),
                SettingsPromptsTile(),
                SettingsWorldBooksTile(),
                SettingsModelSettingsTile(),
                SettingsMemoryWriteFrequencyTile(),
                SettingsMessageDisplayTile(),
                SettingsAgentToolsTile(),
                SettingsMcpServersTile(),
                SettingsSpeechModelsTile(),
                SettingsSpeechOutputTile(),
                SettingsResponseModeSelector(),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionTitle(title: translations.settings.other),
            const SizedBox(height: AppSpacing.sm),
            const SettingsGroup(
              children: [
                SettingsStorageTile(),
                SettingsAboutTile(),
                SettingsDebugPageTile(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
