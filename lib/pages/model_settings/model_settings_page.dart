import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/model/app_preferences_entity.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/settings/settings.dart';

/// 模型采样与上下文相关参数设置页。
class ModelSettingsPage extends StatelessWidget {
  const ModelSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        title: Text(
          translations.settings.modelSettings,
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
          children: const [
            SettingsGroup(
              children: [
                ModelSettingsContextMessageLimitTile(),
                ModelSettingsToolCallRoundsLimitTile(),
                ModelSettingsTemperatureTile(),
                ModelSettingsTopPTile(),
                ModelSettingsTopKTile(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 上下文消息数量限制。
class ModelSettingsContextMessageLimitTile extends ConsumerWidget {
  const ModelSettingsContextMessageLimitTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.settings;
    final enabled = ref.watch(
      appPreferencesProvider.select(
        (state) => state.contextMessageLimitEnabled,
      ),
    );
    final limit = ref.watch(
      appPreferencesProvider.select((state) => state.contextMessageLimit),
    );

    return SettingsListTile(
      onTap: () => showSettingsOptionalSliderSheet(
        context: context,
        title: translations.contextMessageLimit,
        note: translations.contextMessageLimitNote,
        enabled: enabled,
        value: limit.toDouble(),
        min: minContextMessageLimit.toDouble(),
        max: maxContextMessageLimit.toDouble(),
        step: contextMessageLimitStep,
        divisions: maxContextMessageLimit - minContextMessageLimit,
        formatValue: (value) => value.round().toString(),
        onChanged: (result) {
          ref
              .read(appPreferencesProvider.notifier)
              .saveContextMessageLimit(
                enabled: result.enabled,
                limit: result.value.round(),
              );
        },
      ),
      leading: LucideIcons.messagesSquare,
      title: translations.contextMessageLimit,
      subtitle: enabled
          ? translations.contextMessageLimitSubtitleOn(count: limit)
          : translations.contextMessageLimitSubtitleOff,
    );
  }
}

/// 工具调用轮次限制。
class ModelSettingsToolCallRoundsLimitTile extends ConsumerWidget {
  const ModelSettingsToolCallRoundsLimitTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.settings;
    final enabled = ref.watch(
      appPreferencesProvider.select(
        (state) => state.toolCallRoundsLimitEnabled,
      ),
    );
    final limit = ref.watch(
      appPreferencesProvider.select((state) => state.toolCallRoundsLimit),
    );

    return SettingsListTile(
      onTap: () => showSettingsOptionalSliderSheet(
        context: context,
        title: translations.toolCallRoundsLimit,
        note: translations.toolCallRoundsLimitNote,
        enabled: enabled,
        value: limit.toDouble(),
        min: minToolCallRoundsLimit.toDouble(),
        max: maxToolCallRoundsLimit.toDouble(),
        step: toolCallRoundsLimitStep,
        divisions: maxToolCallRoundsLimit - minToolCallRoundsLimit,
        formatValue: (value) => value.round().toString(),
        onChanged: (result) {
          ref
              .read(appPreferencesProvider.notifier)
              .saveToolCallRoundsLimit(
                enabled: result.enabled,
                limit: result.value.round(),
              );
        },
      ),
      leading: LucideIcons.repeat,
      title: translations.toolCallRoundsLimit,
      subtitle: enabled
          ? translations.toolCallRoundsLimitSubtitleOn(count: limit)
          : translations.toolCallRoundsLimitSubtitleOff,
    );
  }
}

/// Temperature。
class ModelSettingsTemperatureTile extends ConsumerWidget {
  const ModelSettingsTemperatureTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.settings;
    final enabled = ref.watch(
      appPreferencesProvider.select((state) => state.temperatureEnabled),
    );
    final temperature = ref.watch(
      appPreferencesProvider.select((state) => state.temperature),
    );
    final temperatureLabel = temperature.toStringAsFixed(2);

    return SettingsListTile(
      onTap: () => showSettingsOptionalSliderSheet(
        context: context,
        title: translations.temperature,
        note: translations.temperatureNote,
        enabled: enabled,
        value: temperature,
        min: minTemperature,
        max: maxTemperature,
        step: temperatureStep,
        divisions: 200,
        formatValue: (value) => value.toStringAsFixed(2),
        onChanged: (result) {
          ref
              .read(appPreferencesProvider.notifier)
              .saveTemperature(
                enabled: result.enabled,
                temperature: result.value,
              );
        },
      ),
      leading: LucideIcons.thermometer,
      title: translations.temperature,
      subtitle: enabled
          ? translations.temperatureSubtitleOn(value: temperatureLabel)
          : translations.temperatureSubtitleOff,
    );
  }
}

/// Top-p：`0` 表示不传参。
class ModelSettingsTopPTile extends ConsumerWidget {
  const ModelSettingsTopPTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.settings;
    final topP = ref.watch(
      appPreferencesProvider.select((state) => state.topP),
    );
    final isUnset = topP <= 0;

    return SettingsListTile(
      onTap: () => showSettingsSliderSheet(
        context: context,
        title: translations.topP,
        note: translations.topPNote,
        value: topP,
        min: minTopP,
        max: maxTopP,
        step: topPStep,
        divisions: 100,
        formatValue: (value) =>
            value <= 0 ? translations.topPUnset : value.toStringAsFixed(2),
        onChanged: (value) {
          ref.read(appPreferencesProvider.notifier).saveTopP(value);
        },
      ),
      leading: LucideIcons.percent,
      title: translations.topP,
      subtitle: isUnset
          ? translations.topPSubtitleOff
          : translations.topPSubtitleOn(value: topP.toStringAsFixed(2)),
    );
  }
}

/// Top-k：`0` 表示不传参。
class ModelSettingsTopKTile extends ConsumerWidget {
  const ModelSettingsTopKTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.settings;
    final topK = ref.watch(
      appPreferencesProvider.select((state) => state.topK),
    );
    final isUnset = topK <= 0;

    return SettingsListTile(
      onTap: () => showSettingsSliderSheet(
        context: context,
        title: translations.topK,
        note: translations.topKNote,
        value: topK.toDouble(),
        min: minTopK.toDouble(),
        max: maxTopK.toDouble(),
        step: topKStep,
        divisions: maxTopK - minTopK,
        formatValue: (value) =>
            value <= 0 ? translations.topKUnset : value.round().toString(),
        onChanged: (value) {
          ref.read(appPreferencesProvider.notifier).saveTopK(value.round());
        },
      ),
      leading: LucideIcons.hash,
      title: translations.topK,
      subtitle: isUnset
          ? translations.topKSubtitleOff
          : translations.topKSubtitleOn(count: topK),
    );
  }
}
