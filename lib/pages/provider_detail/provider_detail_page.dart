import 'package:flute_core/log/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/manage_ai_provider/manage_ai_provider.dart';
import 'package:soulcast/features/transfer_ai_provider/transfer_ai_provider.dart';
import 'package:soulcast/i18n/strings.g.dart';

import 'widget/provider_detail_widgets.dart';

/// 新建或编辑 AI 服务商及其本地模型目录的详情页。
class ProviderDetailPage extends ConsumerStatefulWidget {
  const ProviderDetailPage({required this.providerId, super.key});

  /// 待编辑服务商 id；为空时进入新建模式。
  final String? providerId;

  @override
  ConsumerState<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends ConsumerState<ProviderDetailPage> {
  String? _activeProviderId;

  @override
  void initState() {
    super.initState();
    _activeProviderId = widget.providerId;
  }

  @override
  void didUpdateWidget(covariant ProviderDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providerId == widget.providerId) {
      return;
    }

    _activeProviderId = widget.providerId;
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(aiProvidersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title(context, providersAsync),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          providersAsync.maybeWhen(
            data: (providers) {
              final provider = _selectedProvider(providers);
              if (provider == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: context.t.providerSettings.exportProvider,
                onPressed: () => _exportProvider(provider),
                icon: const Icon(LucideIcons.clipboardCopy),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: providersAsync.when(
          data: (providers) {
            final selectedProvider = _selectedProvider(providers);
            final modelsAsync = selectedProvider == null
                ? const AsyncData(<AiModelEntity>[])
                : ref.watch(aiProviderModelsProvider(selectedProvider.id));

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: context.t.providerSettings.providerTab),
                      Tab(text: context.t.providerSettings.modelsTab),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ProviderDetailConfigTab(
                          selectedProvider: selectedProvider,
                          onProviderSaved: _saveProvider,
                          onProviderDeleted: _deleteProvider,
                        ),
                        ProviderDetailModelsTab(
                          selectedProvider: selectedProvider,
                          models: modelsAsync,
                          onAddModel: _showModelEditorSheet,
                          onFetchModels: _showRemoteModelsSheet,
                          onModelEditing: _showModelEditorSheet,
                          onModelDeleted: _deleteModel,
                          onModelEnabledChanged: _setModelEnabled,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stackTrace) => ProviderDetailProviderStatusView(
            icon: LucideIcons.circleAlert,
            text: error.toString(),
          ),
        ),
      ),
    );
  }

  String _title(
    BuildContext context,
    AsyncValue<List<AiProviderEntity>> providersAsync,
  ) {
    final providerId = _activeProviderId;
    if (providerId == null) {
      return context.t.providerSettings.newProvider;
    }

    final providers = providersAsync.whenOrNull(data: (items) => items);
    final provider = providers == null
        ? null
        : _findProvider(providers, providerId);
    return provider?.name ?? context.t.providerSettings.title;
  }

  AiProviderEntity? _selectedProvider(List<AiProviderEntity> providers) {
    final providerId = _activeProviderId;
    if (providerId == null) {
      return null;
    }
    return _findProvider(providers, providerId);
  }

  AiProviderEntity? _findProvider(
    List<AiProviderEntity> providers,
    String providerId,
  ) {
    for (final provider in providers) {
      if (provider.id == providerId) {
        return provider;
      }
    }
    return null;
  }

  Future<void> _saveProvider(ProviderDetailProviderDraft draft) async {
    final provider = await ref
        .read(manageAiProviderServiceProvider)
        .saveProvider(
          providerId: draft.providerId,
          name: draft.name,
          baseUrl: draft.baseUrl,
          apiPath: draft.apiPath,
          apiKey: draft.apiKey,
          apiMode: draft.apiMode,
          backgroundEnabled: draft.backgroundEnabled,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _activeProviderId = provider.id;
    });
    _showToast(context.t.providerSettings.providerSaved);
  }

  Future<void> _exportProvider(AiProviderEntity provider) async {
    try {
      await ref
          .read(aiProviderTransferServiceProvider)
          .exportToClipboard(provider);
      if (mounted) {
        _showToast(context.t.providerSettings.providerExported);
      }
    } catch (error, stackTrace) {
      Log.e(
        'Provider export failed: $error',
        tag: 'Provider',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showToast(
          context.t.providerSettings.exportProviderFailed(
            error: error.toString(),
          ),
        );
      }
    }
  }

  Future<void> _deleteProvider(AiProviderEntity provider) async {
    final confirmed = await _confirmDelete(
      title: context.t.providerSettings.deleteProviderTitle,
      message: context.t.providerSettings.deleteProviderMessage(
        name: provider.name,
      ),
    );
    if (!confirmed) {
      return;
    }

    await ref.read(manageAiProviderServiceProvider).deleteProvider(provider.id);
    if (!mounted) {
      return;
    }

    _showToast(context.t.providerSettings.providerDeleted);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _activeProviderId = null;
    });
  }

  Future<void> _saveModel(
    String providerId,
    ProviderDetailModelDraft draft, {
    String? successMessage,
  }) async {
    await ref
        .read(manageAiProviderServiceProvider)
        .saveModel(
          modelId: draft.modelId,
          providerId: providerId,
          name: draft.name,
          model: draft.model,
          isEnabled: draft.isEnabled,
          inputFormats: draft.inputFormats,
          outputFormats: draft.outputFormats,
        );

    if (!mounted) {
      return;
    }

    _showToast(successMessage ?? context.t.providerSettings.modelSaved);
  }

  Future<bool> _addRemoteModel({
    required String providerId,
    required RemoteAiModel remoteModel,
  }) async {
    final translations = context.t.providerSettings;
    final imported = await ref
        .read(manageAiProviderServiceProvider)
        .importRemoteModel(providerId: providerId, remoteModel: remoteModel);
    if (!mounted) {
      return imported;
    }
    if (!imported) {
      _showToast(translations.modelAlreadyExists);
      return false;
    }
    _showToast(translations.modelImported);
    return true;
  }

  Future<void> _deleteModel(AiModelEntity model) async {
    final confirmed = await _confirmDelete(
      title: context.t.providerSettings.deleteModelTitle,
      message: context.t.providerSettings.deleteModelMessage(name: model.name),
    );
    if (!confirmed) {
      return;
    }

    await ref.read(manageAiProviderServiceProvider).deleteModel(model.id);
    if (!mounted) {
      return;
    }

    _showToast(context.t.providerSettings.modelDeleted);
  }

  Future<void> _setModelEnabled({
    required String modelId,
    required bool isEnabled,
  }) async {
    await ref
        .read(manageAiProviderServiceProvider)
        .setModelEnabled(modelId: modelId, isEnabled: isEnabled);
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                context.t.common.cancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                context.t.common.delete,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  void _showToast(String message) => SmartDialog.showToast(message);

  Future<void> _showModelEditorSheet(
    AiProviderEntity provider, {
    AiModelEntity? model,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return ProviderDetailModelEditorSheet(
          model: model,
          onSaved: (draft) async {
            await _saveModel(provider.id, draft);
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _showRemoteModelsSheet(
    AiProviderEntity provider,
    List<AiModelEntity> existingModels,
  ) {
    final manage = ref.read(manageAiProviderServiceProvider);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return ProviderDetailRemoteModelsSheet(
          existingModelIds: existingModels
              .map((model) => model.model.trim())
              .where((modelId) => modelId.isNotEmpty)
              .toSet(),
          onFetchModels: () {
            return manage.fetchRemoteModels(
              baseUrl: provider.baseUrl,
              apiKey: provider.apiKey,
            );
          },
          onModelAdded: (remoteModel) {
            return _addRemoteModel(
              providerId: provider.id,
              remoteModel: remoteModel,
            );
          },
        );
      },
    );
  }
}
