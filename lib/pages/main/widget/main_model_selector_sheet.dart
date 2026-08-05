import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 主聊天页模型选择底部面板。
class MainModelSelectorSheet extends StatelessWidget {
  const MainModelSelectorSheet({
    super.key,
    required this.models,
    required this.providers,
    required this.selectedModelId,
    required this.onModelSelected,
    required this.onManageProviders,
  });

  final AsyncValue<List<AiModelEntity>> models;
  final AsyncValue<List<AiProviderEntity>> providers;
  final String? selectedModelId;
  final ValueChanged<String> onModelSelected;
  final VoidCallback onManageProviders;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.main.modelSelector;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  translations.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: translations.manage,
                onPressed: onManageProviders,
                icon: const Icon(LucideIcons.settings),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: models.when(
              data: (items) {
                final enabledModels = items
                    .where(
                      (model) =>
                          model.isEnabled &&
                          model.hasInputFormat(AiModelFormatTags.text) &&
                          model.hasOutputFormat(AiModelFormatTags.text),
                    )
                    .toList();
                if (enabledModels.isEmpty) {
                  return MainModelSelectorStatus(
                    icon: LucideIcons.bot,
                    text: translations.noModels,
                  );
                }

                final providerMap = {
                  for (final provider
                      in providers.whenOrNull(data: (items) => items) ??
                          const <AiProviderEntity>[])
                    provider.id: provider,
                };
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: enabledModels.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final model = enabledModels[index];
                    final provider = providerMap[model.providerId];
                    return MainModelSelectorItem(
                      model: model,
                      providerName: provider?.name ?? translations.unknown,
                      isSelected: model.id == selectedModelId,
                      onTap: () => onModelSelected(model.id),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (error, stackTrace) => MainModelSelectorStatus(
                icon: LucideIcons.circleAlert,
                text: error.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 模型选择列表项。
class MainModelSelectorItem extends StatelessWidget {
  const MainModelSelectorItem({
    super.key,
    required this.model,
    required this.providerName,
    required this.isSelected,
    required this.onTap,
  });

  final AiModelEntity model;
  final String providerName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.surface
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Icon(
                      isSelected ? LucideIcons.check : LucideIcons.bot,
                      size: 18,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$providerName · ${model.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 模型选择空态 / 错误态。
class MainModelSelectorStatus extends StatelessWidget {
  const MainModelSelectorStatus({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
