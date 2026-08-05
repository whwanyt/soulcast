import 'package:flute_core/log/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

import '../provider/mcp_server_transfer_service.dart';
import '../service/mcp_server_json_codec.dart';

/// 粘贴并校验 MCP Server JSON 的导入底部面板。
class McpServerImportSheet extends ConsumerStatefulWidget {
  const McpServerImportSheet({super.key});

  @override
  ConsumerState<McpServerImportSheet> createState() =>
      _McpServerImportSheetState();
}

class _McpServerImportSheetState extends ConsumerState<McpServerImportSheet> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _isImporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.mcpSettings;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.importServersTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            translations.importServersDescription,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            key: const ValueKey('mcp_server_import_json_field'),
            controller: _controller,
            autofocus: true,
            labelText: translations.importServersJsonLabel,
            hintText: translations.importServersJsonHint,
            minLines: 7,
            maxLines: 14,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isImporting ? null : _import,
            icon: const Icon(LucideIcons.import),
            label: Text(
              translations.importServersConfirm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _import() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isImporting = true;
      _errorText = null;
    });

    try {
      final repository = await ref.read(
        mcpServerConfigRepositoryProvider.future,
      );
      final imported = ref
          .read(mcpServerTransferServiceProvider)
          .importFromJson(json: _controller.text, repository: repository);
      if (mounted) {
        Navigator.of(context).pop(imported);
      }
    } on McpServerJsonException catch (error, stackTrace) {
      Log.e(
        'MCP import JSON failed: $error',
        tag: 'Mcp',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _errorText = _messageFor(error.error));
      }
    } catch (error, stackTrace) {
      Log.e(
        'MCP import failed: $error',
        tag: 'Mcp',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(
          () => _errorText = context.t.mcpSettings.importServersFailed(
            error: error.toString(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  String _messageFor(McpServerJsonError error) {
    return switch (error) {
      McpServerJsonError.invalidJson =>
        context.t.mcpSettings.importServersInvalidJson,
      McpServerJsonError.invalidFields =>
        context.t.mcpSettings.importServersInvalidFields,
      McpServerJsonError.missingRequiredField =>
        context.t.mcpSettings.importServersMissingRequired,
      McpServerJsonError.unsupportedType =>
        context.t.mcpSettings.importServersUnsupportedType,
    };
  }
}
