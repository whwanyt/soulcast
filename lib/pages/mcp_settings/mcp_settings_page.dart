import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';
import 'package:soulcast/features/mcp/mcp.dart';
import 'package:soulcast/features/transfer_mcp/transfer_mcp.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// MCP Server 列表与导入、新建入口页面。
class McpSettingsPage extends ConsumerWidget {
  const McpSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(mcpServersProvider);
    final sessions = ref.watch(mcpSessionManagerProvider);
    final translations = context.t.mcpSettings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translations.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: translations.importServers,
            onPressed: () => _showImportSheet(context, ref),
            icon: const Icon(LucideIcons.import),
          ),
          IconButton(
            tooltip: translations.newServer,
            onPressed: () => const McpServerEditRoute().push(context),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: SafeArea(
        child: serversAsync.when(
          data: (servers) {
            if (servers.isEmpty) {
              return _McpEmptyView(
                onAdd: () => const McpServerEditRoute().push(context),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: servers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final server = servers[index];
                return _McpServerListTile(
                  server: server,
                  session: sessions[server.id],
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stackTrace) => Center(
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

  Future<void> _showImportSheet(BuildContext context, WidgetRef ref) async {
    final imported = await showModalBottomSheet<List<McpServerConfigEntity>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const McpServerImportSheet(),
    );
    if (imported == null || imported.isEmpty || !context.mounted) {
      return;
    }

    final manager = ref.read(mcpSessionManagerProvider.notifier);
    await Future.wait([
      for (final server in imported)
        if (server.enabled) manager.connectServer(server),
    ]);

    if (!context.mounted) {
      return;
    }
    SmartDialog.showToast(
      context.t.mcpSettings.serversImported(count: imported.length),
    );
  }
}

class _McpServerListTile extends ConsumerWidget {
  const _McpServerListTile({required this.server, required this.session});

  final McpServerConfigEntity server;
  final McpServerSessionState? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = context.t.mcpSettings;
    final String statusText;
    if (!server.enabled) {
      statusText = translations.statusDisabled;
    } else {
      statusText = switch (session?.status) {
        McpConnectionStatus.connecting => translations.statusConnecting,
        McpConnectionStatus.connected => translations.statusConnected(
          count: session?.discoveredToolCount ?? 0,
        ),
        McpConnectionStatus.error => translations.statusError(
          error: session?.errorMessage ?? '',
        ),
        _ => translations.statusDisconnected,
      };
    }

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        titleAlignment: ListTileTitleAlignment.center,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        onTap: () => McpServerEditRoute(serverId: server.id).push(context),
        leading: Icon(LucideIcons.server, color: colorScheme.onSurfaceVariant),
        title: Text(server.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${server.url}\n$statusText',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Switch.adaptive(
          value: server.enabled,
          onChanged: (value) {
            ref
                .read(mcpServerActionsProvider.notifier)
                .setEnabled(server.id, enabled: value);
          },
        ),
      ),
    );
  }
}

class _McpEmptyView extends StatelessWidget {
  const _McpEmptyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.mcpSettings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.server,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              translations.empty,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(LucideIcons.plus),
                label: Text(
                  translations.newServer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
