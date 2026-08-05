import 'package:flute_core/log/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

import '../provider/ai_provider_transfer_service.dart';
import '../service/ai_provider_json_codec.dart';

/// 粘贴并校验 AI 服务商 JSON 的导入底部面板。
class AiProviderImportSheet extends ConsumerStatefulWidget {
  const AiProviderImportSheet({super.key});

  @override
  ConsumerState<AiProviderImportSheet> createState() =>
      _AiProviderImportSheetState();
}

class _AiProviderImportSheetState extends ConsumerState<AiProviderImportSheet> {
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
    final translations = context.t.providerSettings;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.importProviderTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            translations.importProviderDescription,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            key: const ValueKey('ai_provider_import_json_field'),
            controller: _controller,
            autofocus: true,
            labelText: translations.importProviderJsonLabel,
            hintText: translations.importProviderJsonHint,
            minLines: 7,
            maxLines: 12,
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
              translations.importProviderConfirm,
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
      final repository = await ref.read(aiProviderRepositoryProvider.future);
      final provider = ref
          .read(aiProviderTransferServiceProvider)
          .importFromJson(json: _controller.text, repository: repository);
      if (mounted) {
        Navigator.of(context).pop(provider);
      }
    } on AiProviderJsonException catch (error, stackTrace) {
      Log.e(
        'Provider import JSON failed: $error',
        tag: 'Provider',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _errorText = _messageFor(error.error));
      }
    } catch (error, stackTrace) {
      Log.e(
        'Provider import failed: $error',
        tag: 'Provider',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(
          () => _errorText = context.t.providerSettings.importProviderFailed(
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

  String _messageFor(AiProviderJsonError error) {
    return switch (error) {
      AiProviderJsonError.invalidJson =>
        context.t.providerSettings.importProviderInvalidJson,
      AiProviderJsonError.invalidFields =>
        context.t.providerSettings.importProviderInvalidFields,
      AiProviderJsonError.missingRequiredField =>
        context.t.providerSettings.importProviderMissingRequired,
    };
  }
}
