import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';
import 'package:soulcast/i18n/strings.g.dart';

import '../model/mcp_remote_tool.dart';
import '../provider/mcp_tools.dart';
import '../service/mcp_session_manager.dart';

/// 聊天页底部 MCP 工具开关面板（仅启用/禁用，不含 Server 配置）。
///
/// 与本地 [AgentToolPanel] 分离：只展示 MCP 远程工具，数据来自
/// [mcpDiscoveredToolsProvider]（与设置页同源）。
class McpToolPanel extends ConsumerStatefulWidget {
  const McpToolPanel({super.key});

  @override
  ConsumerState<McpToolPanel> createState() => _McpToolPanelState();
}

class _McpToolPanelState extends ConsumerState<McpToolPanel> {
  var _didRequestSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didRequestSync) {
        return;
      }
      _didRequestSync = true;
      final tools = ref.read(mcpDiscoveredToolsProvider);
      if (tools.isNotEmpty) {
        return;
      }
      // 设置页已有 Server，但会话可能尚未连上；打开面板时补一次同步。
      ref.read(mcpSessionManagerProvider.notifier).syncEnabledServers();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mcpServerActionsProvider);
    final tools = ref.watch(mcpDiscoveredToolsProvider);
    final serversAsync = ref.watch(mcpServersProvider);
    final servers = serversAsync.whenOrNull(data: (items) => items) ?? const [];
    final disabledByServer = {
      for (final server in servers)
        server.id: McpServerConfigRepository.decodeDisabledToolNames(
          server.disabledToolNamesJson,
        ).toSet(),
    };
    final translations = context.t.main.mcpPanel;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.45;

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
          if (tools.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                translations.empty,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: tools.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  final isEnabled =
                      !(disabledByServer[tool.serverId]?.contains(
                            tool.originalName,
                          ) ??
                          false);
                  return _McpToolPanelItem(
                    tool: tool,
                    isEnabled: isEnabled,
                    onEnabledChanged: (value) {
                      ref
                          .read(mcpServerActionsProvider.notifier)
                          .setToolEnabled(
                            serverId: tool.serverId,
                            originalName: tool.originalName,
                            enabled: value,
                          );
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

class _McpToolPanelItem extends StatelessWidget {
  const _McpToolPanelItem({
    required this.tool,
    required this.isEnabled,
    required this.onEnabledChanged,
  });

  final McpRemoteTool tool;
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
        key: ValueKey('mcp_tool_switch_${tool.qualifiedName}'),
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
