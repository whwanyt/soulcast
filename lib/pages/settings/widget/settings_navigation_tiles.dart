part of '../settings_page.dart';

/// 用户昵称设置项，底部面板编辑并持久化。
class SettingsUserNicknameTile extends ConsumerWidget {
  const SettingsUserNicknameTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.settings;
    final nickname = ref.watch(
      appPreferencesProvider.select((state) => state.user),
    );
    final displayName = nickname?.trim();
    final hasNickname = displayName != null && displayName.isNotEmpty;

    return SettingsListTile(
      onTap: () async {
        final next = await showSettingsUserNicknameSheet(
          context: context,
          initialValue: displayName ?? '',
        );
        if (next == null || !context.mounted) {
          return;
        }
        await ref.read(appPreferencesProvider.notifier).saveUser(next);
      },
      leading: LucideIcons.userRound,
      title: translations.userNickname,
      subtitle: hasNickname ? displayName : translations.userNicknameEmpty,
    );
  }
}

/// AI 服务商设置入口。
class SettingsProviderTile extends StatelessWidget {
  const SettingsProviderTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const ProviderSettingsRoute().push(context),
      leading: LucideIcons.boxes,
      title: translations.settings.aiProvider,
      subtitle: translations.settings.aiProviderSubtitle,
    );
  }
}

/// 可配置提示词中心入口。
class SettingsPromptsTile extends StatelessWidget {
  const SettingsPromptsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const PromptsRoute().push(context),
      leading: LucideIcons.brainCircuit,
      title: translations.settings.prompts,
      subtitle: translations.settings.promptsSubtitle,
    );
  }
}

/// 独立世界书资源库入口。
class SettingsWorldBooksTile extends StatelessWidget {
  const SettingsWorldBooksTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const WorldBookSettingsRoute().push(context),
      leading: LucideIcons.bookOpen,
      title: translations.settings.worldBooks,
      subtitle: translations.settings.worldBooksSubtitle,
    );
  }
}

/// 模型采样与上下文参数入口。
class SettingsModelSettingsTile extends StatelessWidget {
  const SettingsModelSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const ModelSettingsRoute().push(context),
      leading: LucideIcons.slidersHorizontal,
      title: translations.settings.modelSettings,
      subtitle: translations.settings.modelSettingsSubtitle,
    );
  }
}

/// 消息显示设置入口。
class SettingsMessageDisplayTile extends StatelessWidget {
  const SettingsMessageDisplayTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const MessageDisplaySettingsRoute().push(context),
      leading: LucideIcons.eye,
      title: translations.settings.messageDisplay,
      subtitle: translations.settings.messageDisplaySubtitle,
    );
  }
}

/// Agent 工具设置入口。
class SettingsAgentToolsTile extends StatelessWidget {
  const SettingsAgentToolsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const AgentToolSettingsRoute().push(context),
      leading: LucideIcons.wrench,
      title: translations.settings.agentTools,
      subtitle: translations.settings.agentToolsSubtitle,
    );
  }
}

/// MCP Server 设置入口。
class SettingsMcpServersTile extends StatelessWidget {
  const SettingsMcpServersTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const McpSettingsRoute().push(context),
      leading: LucideIcons.server,
      title: translations.settings.mcpServers,
      subtitle: translations.settings.mcpServersSubtitle,
    );
  }
}

/// 语音模型设置入口。
class SettingsSpeechModelsTile extends StatelessWidget {
  const SettingsSpeechModelsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const SpeechModelSettingsRoute().push(context),
      leading: LucideIcons.audioLines,
      title: translations.settings.speechModels,
      subtitle: translations.settings.speechModelsSubtitle,
    );
  }
}

/// TTS 输出设置入口。
class SettingsSpeechOutputTile extends StatelessWidget {
  const SettingsSpeechOutputTile({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return SettingsListTile(
      onTap: () => const SpeechOutputSettingsRoute().push(context),
      leading: LucideIcons.volume2,
      title: translations.settings.speechOutput,
      subtitle: translations.settings.speechOutputSubtitle,
    );
  }
}
