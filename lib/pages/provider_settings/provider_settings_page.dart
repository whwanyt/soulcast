import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/transfer_ai_provider/transfer_ai_provider.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// AI 服务商列表与导入、新建入口页面。
class ProviderSettingsPage extends ConsumerWidget {
  const ProviderSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(aiProvidersProvider);
    final translations = context.t.providerSettings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translations.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: translations.importProvider,
            onPressed: () => _showImportSheet(context),
            icon: const Icon(LucideIcons.import),
          ),
          IconButton(
            tooltip: translations.newProvider,
            onPressed: () => const ProviderDetailRoute().push(context),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: SafeArea(
        child: providersAsync.when(
          data: (providers) {
            if (providers.isEmpty) {
              return _ProviderEmptyView(
                onAddProvider: () => const ProviderDetailRoute().push(context),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemBuilder: (context, index) {
                final provider = providers[index];
                return _ProviderListTile(provider: provider);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: providers.length,
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stackTrace) => _ProviderStatusView(
            icon: LucideIcons.circleAlert,
            text: error.toString(),
          ),
        ),
      ),
    );
  }

  Future<void> _showImportSheet(BuildContext context) async {
    final provider = await showModalBottomSheet<AiProviderEntity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const AiProviderImportSheet(),
    );
    if (provider == null || !context.mounted) {
      return;
    }

    SmartDialog.showToast(context.t.providerSettings.providerImported);
  }
}

class _ProviderListTile extends StatelessWidget {
  const _ProviderListTile({required this.provider});

  final AiProviderEntity provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        onTap: () {
          ProviderDetailRoute(providerId: provider.id).push(context);
        },
        titleAlignment: ListTileTitleAlignment.center,
        leading: Icon(
          LucideIcons.building2,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(
          provider.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${provider.baseUrl}${provider.apiPath}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(LucideIcons.chevronRight),
      ),
    );
  }
}

class _ProviderEmptyView extends StatelessWidget {
  const _ProviderEmptyView({required this.onAddProvider});

  final VoidCallback onAddProvider;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.providerSettings;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProviderStatusView(
              icon: LucideIcons.building2,
              text: translations.noProviders,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: onAddProvider,
                icon: const Icon(LucideIcons.plus),
                label: Text(
                  translations.addProvider,
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

class _ProviderStatusView extends StatelessWidget {
  const _ProviderStatusView({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
