part of '../settings_page.dart';

/// 长期记忆写入频率设置项。
class SettingsMemoryWriteFrequencyTile extends ConsumerWidget {
  const SettingsMemoryWriteFrequencyTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.settings;
    final enabled = ref.watch(
      appPreferencesProvider.select(
        (state) => state.memoryWriteFrequencyEnabled,
      ),
    );
    final frequency = ref.watch(
      appPreferencesProvider.select((state) => state.memoryWriteFrequency),
    );

    return SettingsListTile(
      onTap: () => showSettingsOptionalSliderSheet(
        context: context,
        title: translations.memoryWriteFrequency,
        note: translations.memoryWriteFrequencyNote,
        enabled: enabled,
        value: frequency.toDouble(),
        min: minMemoryWriteFrequency.toDouble(),
        max: maxMemoryWriteFrequency.toDouble(),
        step: memoryWriteFrequencyStep,
        divisions: maxMemoryWriteFrequency - minMemoryWriteFrequency,
        formatValue: (value) => value.round().toString(),
        onChanged: (result) {
          ref
              .read(appPreferencesProvider.notifier)
              .saveMemoryWriteFrequency(
                enabled: result.enabled,
                frequency: result.value.round(),
              );
        },
      ),
      leading: LucideIcons.brain,
      title: translations.memoryWriteFrequency,
      subtitle: enabled
          ? translations.memoryWriteFrequencySubtitleOn(count: frequency)
          : translations.memoryWriteFrequencySubtitleOff,
    );
  }
}

/// 流式或普通回复模式选择器。
class SettingsResponseModeSelector extends ConsumerWidget {
  const SettingsResponseModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final selectedResponseMode = ref.watch(
      appPreferencesProvider.select((state) => state.responseMode),
    );

    return SettingsDropdownTile<ChatResponseModePreference>(
      leading: LucideIcons.zap,
      title: translations.settings.responseMode,
      value: selectedResponseMode,
      valueLabel: selectedResponseMode.label(translations),
      options: ChatResponseModePreference.values,
      optionLabel: (mode) => mode.label(translations),
      onSelected: (mode) {
        ref.read(appPreferencesProvider.notifier).selectResponseMode(mode);
      },
    );
  }
}
