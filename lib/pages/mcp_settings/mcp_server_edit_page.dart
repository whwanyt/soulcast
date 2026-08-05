import 'package:flute_core/log/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';
import 'package:soulcast/features/mcp/mcp.dart';
import 'package:soulcast/features/transfer_mcp/transfer_mcp.dart';
import 'package:soulcast/i18n/strings.g.dart';

/// 新建、编辑与测试 MCP Server 连接配置的页面。
class McpServerEditPage extends ConsumerStatefulWidget {
  const McpServerEditPage({this.serverId, super.key});

  /// 待编辑 Server id；为空时进入新建模式。
  final String? serverId;

  @override
  ConsumerState<McpServerEditPage> createState() => _McpServerEditPageState();
}

class _McpServerEditPageState extends ConsumerState<McpServerEditPage> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _disabledToolNames = <String>{};
  var _enabled = true;
  var _obscureToken = true;
  var _initialized = false;
  var _saving = false;
  var _testing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.mcpSettings;
    final serversAsync = ref.watch(mcpServersProvider);

    if (!_initialized && widget.serverId != null) {
      final servers = serversAsync.whenOrNull(data: (items) => items);
      final server = servers == null
          ? null
          : _findInList(servers, widget.serverId!);
      if (server != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _initialized) {
            return;
          }
          _hydrate(server);
        });
      }
    }

    final connectedTools = widget.serverId == null
        ? const <McpRemoteTool>[]
        : ref.watch(mcpDiscoveredToolsForServerProvider(widget.serverId!));
    final existing = widget.serverId == null
        ? null
        : () {
            final servers = serversAsync.whenOrNull(data: (items) => items);
            if (servers == null) {
              return null;
            }
            return _findInList(servers, widget.serverId!);
          }();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.serverId == null
              ? translations.newServer
              : translations.editServer,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.serverId != null) ...[
            IconButton(
              tooltip: translations.exportServer,
              onPressed: existing == null
                  ? null
                  : () => _exportServer(existing),
              icon: const Icon(LucideIcons.clipboardCopy),
            ),
            IconButton(
              tooltip: translations.delete,
              onPressed: existing == null ? null : () => _delete(existing),
              icon: const Icon(LucideIcons.trash2),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: translations.nameLabel,
                hintText: translations.nameHint,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: translations.urlLabel,
                hintText: translations.urlHint,
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              obscureText: _obscureToken,
              decoration: InputDecoration(
                labelText: translations.bearerTokenLabel,
                hintText: translations.bearerTokenHint,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscureToken = !_obscureToken);
                  },
                  icon: Icon(
                    _obscureToken ? LucideIcons.eye : LucideIcons.eyeOff,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                translations.enabledLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _testing ? null : _testConnection,
                    child: Text(
                      _testing
                          ? translations.testing
                          : translations.testConnection,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving ? translations.saving : translations.save,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (connectedTools.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                translations.toolsSection,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                translations.toolsSectionHint,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final tool in connectedTools)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tool.originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    tool.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: !_disabledToolNames.contains(tool.originalName),
                  onChanged: (enabled) {
                    setState(() {
                      if (enabled) {
                        _disabledToolNames.remove(tool.originalName);
                      } else {
                        _disabledToolNames.add(tool.originalName);
                      }
                    });
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _hydrate(McpServerConfigEntity server) {
    _initialized = true;
    _nameController.text = server.name;
    _urlController.text = server.url;
    _tokenController.text = server.bearerToken;
    _enabled = server.enabled;
    _disabledToolNames
      ..clear()
      ..addAll(
        McpServerConfigRepository.decodeDisabledToolNames(
          server.disabledToolNamesJson,
        ),
      );
    setState(() {});
  }

  McpServerConfigEntity? _findInList(
    List<McpServerConfigEntity> servers,
    String serverId,
  ) {
    for (final server in servers) {
      if (server.id == serverId) {
        return server;
      }
    }
    return null;
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      SmartDialog.showToast(context.t.mcpSettings.urlRequired);
      return;
    }
    setState(() => _testing = true);
    try {
      final count = await ref
          .read(mcpServerActionsProvider.notifier)
          .testConnection(url: url, bearerToken: _tokenController.text);
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(context.t.mcpSettings.testSuccess(count: count));
    } catch (error, stackTrace) {
      Log.e(
        'MCP test connection failed: $error',
        tag: 'MCP',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(
        context.t.mcpSettings.testFailed(error: error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final translations = context.t.mcpSettings;
    if (name.isEmpty) {
      SmartDialog.showToast(translations.nameRequired);
      return;
    }
    if (url.isEmpty) {
      SmartDialog.showToast(translations.urlRequired);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(mcpServerActionsProvider.notifier)
          .saveServer(
            serverId: widget.serverId,
            name: name,
            url: url,
            enabled: _enabled,
            bearerToken: _tokenController.text,
            disabledToolNames: _disabledToolNames.toList(growable: false),
          );
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(translations.saved);
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      Log.e(
        'MCP server save failed: $error',
        tag: 'MCP',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(translations.saveFailed(error: error.toString()));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _exportServer(McpServerConfigEntity server) async {
    try {
      await ref
          .read(mcpServerTransferServiceProvider)
          .exportToClipboard(server);
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(context.t.mcpSettings.serverExported);
    } catch (error, stackTrace) {
      Log.e(
        'MCP export failed: $error',
        tag: 'MCP',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(
        context.t.mcpSettings.exportServerFailed(error: error.toString()),
      );
    }
  }

  Future<void> _delete(McpServerConfigEntity server) async {
    final translations = context.t.mcpSettings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            translations.deleteTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(
            translations.deleteMessage(name: server.name),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.t.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(translations.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(mcpServerActionsProvider.notifier).deleteServer(server.id);
    if (!mounted) {
      return;
    }
    SmartDialog.showToast(translations.deleted);
    Navigator.of(context).pop();
  }
}
