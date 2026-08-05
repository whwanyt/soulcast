import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulcast/i18n/strings.g.dart';

import '../model/agent_tool_config.dart';
import '../provider/agent_tools.dart';
import '../service/agent_tool.dart';

/// 聊天页底部工具开关面板（仅启用/禁用，不含扩展参数配置）。
class AgentToolPanel extends ConsumerWidget {
  const AgentToolPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = ref.watch(availableAgentToolsProvider);
    final configs = ref.watch(agentToolConfigsProvider);
    final translations = context.t.main.toolPanel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            translations.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: tools.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tool = tools[index];
                final config =
                    configs[tool.name] ?? const AgentToolConfig(enabled: true);
                return _AgentToolPanelItem(
                  tool: tool,
                  isEnabled: config.enabled,
                  onEnabledChanged: (value) {
                    ref
                        .read(agentToolConfigsProvider.notifier)
                        .setEnabled(tool.name, isEnabled: value);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentToolPanelItem extends StatelessWidget {
  const _AgentToolPanelItem({
    required this.tool,
    required this.isEnabled,
    required this.onEnabledChanged,
  });

  final AgentTool tool;
  final bool isEnabled;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        key: ValueKey('agent_tool_switch_${tool.name}'),
        value: isEnabled,
        onChanged: onEnabledChanged,
        title: Text(
          tool.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          tool.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
