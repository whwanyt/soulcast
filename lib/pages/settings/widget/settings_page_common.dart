part of '../settings_page.dart';

/// 设置分组标题。
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 亮色或暗色主题模式选择器。
class SettingsThemeModeSelector extends ConsumerWidget {
  const SettingsThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final selectedThemeMode = ref.watch(
      appPreferencesProvider.select((state) => state.themeMode),
    );

    return SettingsDropdownTile<AppThemeModePreference>(
      leading: LucideIcons.sun,
      title: translations.settings.appearance,
      value: selectedThemeMode,
      valueLabel: selectedThemeMode.label(translations),
      options: AppThemeModePreference.values,
      optionLabel: (themeMode) => themeMode.label(translations),
      onSelected: (themeMode) {
        ref.read(appPreferencesProvider.notifier).selectThemeMode(themeMode);
      },
    );
  }
}

/// 应用语言设置入口。
class SettingsLanguageTile extends ConsumerWidget {
  const SettingsLanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final locale = ref.watch(
      appPreferencesProvider.select((state) => state.locale),
    );
    final currentLanguage = appLanguageOptions.firstWhere(
      (option) => option.locale == locale,
      orElse: () => appLanguageOptions.first,
    );

    return SettingsListTile(
      onTap: () => const LanguageRoute().push(context),
      leading: LucideIcons.languages,
      title: translations.settings.language,
      subtitle: currentLanguage.localizedName(translations),
    );
  }
}

/// 存储管理入口。
class SettingsStorageTile extends StatelessWidget {
  const SettingsStorageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const StorageRoute().push(context),
      leading: LucideIcons.hardDrive,
      title: translations.settings.storage,
      subtitle: translations.settings.storageSubtitle,
    );
  }
}

/// 关于我们入口。
class SettingsAboutTile extends StatelessWidget {
  const SettingsAboutTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const AboutRoute().push(context),
      leading: LucideIcons.info,
      title: translations.settings.about,
      subtitle: translations.settings.aboutSubtitle,
    );
  }
}

/// 调试页面入口。
class SettingsDebugPageTile extends StatelessWidget {
  const SettingsDebugPageTile({super.key});

  /// 构建调试页入口。
  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const DebugRoute().push(context),
      leading: LucideIcons.bug,
      title: translations.settings.debug,
      subtitle: translations.settings.debugSubtitle,
    );
  }
}
