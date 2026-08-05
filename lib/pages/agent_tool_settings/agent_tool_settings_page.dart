import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 配置本地 Agent 工具扩展参数的设置页。
class AgentToolSettingsPage extends ConsumerWidget {
  const AgentToolSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.agentToolSettings;
    final tools = ref
        .watch(availableAgentToolsProvider)
        .where((tool) => tool.settingFields.isNotEmpty)
        .toList(growable: false);
    final configs = ref.watch(agentToolConfigsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translations.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: tools.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    translations.empty,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: tools.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Text(
                      translations.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  }

                  final tool = tools[index - 1];
                  final config =
                      configs[tool.name] ??
                      const AgentToolConfig(enabled: true);
                  return AgentToolSettingsCard(
                    tool: tool,
                    config: config,
                    onParamChanged: (key, value) {
                      ref
                          .read(agentToolConfigsProvider.notifier)
                          .setParam(tool.name, key, value);
                    },
                  );
                },
              ),
      ),
    );
  }
}
