import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/features/manage_storage/manage_storage.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/storage/widget/storage_category_style.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/utils/directory_usage.dart';

/// 存储管理入口页。
///
/// 监听各分类的占用快照，并统一展示总占用、分类占比与详情页入口。
class StoragePage extends ConsumerWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final usageAsync = ref.watch(storageUsageProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        title: Text(
          translations.storage.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: translations.storage.refresh,
            onPressed: () => ref.read(storageUsageProvider.notifier).refresh(),
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: SafeArea(
        child: usageAsync.when(
          data: (snapshot) => StoragePageBody(snapshot: snapshot),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                translations.storage.loadFailed(error: error.toString()),
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
}

/// 存储管理页的数据态内容。
class StoragePageBody extends StatelessWidget {
  const StoragePageBody({required this.snapshot, super.key});

  /// 本次扫描得到的存储占用快照。
  final StorageUsageSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      children: [
        StorageOverviewCard(snapshot: snapshot),
        const SizedBox(height: AppSpacing.xl),
        StorageCategoryGroup(
          children: [
            for (final usage in snapshot.categories)
              StorageCategoryTile(usage: usage),
          ],
        ),
      ],
    );
  }
}

/// 将存储分类条目组合成带分隔线的卡片列表。
class StorageCategoryGroup extends StatelessWidget {
  const StorageCategoryGroup({required this.children, super.key});

  /// 按展示顺序排列的分类条目。
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              Divider(height: 1, thickness: 1, indent: 52, color: dividerColor),
          ],
        ],
      ),
    );
  }
}

/// 展示总占用、分类占比条和图例的概览卡片。
class StorageOverviewCard extends StatelessWidget {
  const StorageOverviewCard({required this.snapshot, super.key});

  /// 用于汇总总占用和非空分类的数据快照。
  final StorageUsageSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final segments = snapshot.nonEmptyCategories;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translations.storage.usedSpace,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatByteSize(snapshot.totalBytes),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            StorageUsageBar(
              segments: segments,
              totalBytes: snapshot.totalBytes,
            ),
            if (segments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final usage in segments)
                    StorageLegendDot(
                      color: StorageCategoryStyle.chartColor(usage.category),
                      label: _categoryLabel(translations, usage.category),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 按各分类字节数比例绘制存储占用条。
class StorageUsageBar extends StatelessWidget {
  const StorageUsageBar({
    required this.segments,
    required this.totalBytes,
    super.key,
  });

  /// 需要绘制的非空分类占用数据。
  final List<StorageCategoryUsage> segments;

  /// 所有分类的总字节数，用作各分段的比例基数。
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: SizedBox(
        height: 10,
        child: totalBytes <= 0 || segments.isEmpty
            ? ColoredBox(color: colorScheme.surfaceContainerHigh)
            : Row(
                children: [
                  for (final usage in segments)
                    Expanded(
                      // 至少保留一个 flex，避免极小但非空的分类完全不可见。
                      flex: usage.bytes.clamp(1, totalBytes),
                      child: ColoredBox(
                        color: StorageCategoryStyle.chartColor(usage.category),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// 存储分类图例项，由色点和分类名称组成。
class StorageLegendDot extends StatelessWidget {
  const StorageLegendDot({required this.color, required this.label, super.key});

  /// 与占用条分段一致的分类颜色。
  final Color color;

  /// 本地化后的分类名称。
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// 单个存储分类入口，展示占用统计并跳转至分类详情页。
class StorageCategoryTile extends StatelessWidget {
  const StorageCategoryTile({required this.usage, super.key});

  /// 当前分类的占用与条目数量。
  final StorageCategoryUsage usage;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = _categoryLabel(translations, usage.category);
    final stats = _categoryStatsLabel(translations, usage);

    return InkWell(
      onTap: () =>
          StorageCategoryRoute(category: usage.category.name).push(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              StorageCategoryStyle.icon(usage.category),
              size: 22,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// 将存储分类映射为本地化名称。
String _categoryLabel(Translations translations, StorageCategory category) {
  final categories = translations.storage.categories;
  return switch (category) {
    StorageCategory.images => categories.images,
    StorageCategory.files => categories.files,
    StorageCategory.chatHistory => categories.chatHistory,
    StorageCategory.assistant => categories.assistant,
    StorageCategory.cache => categories.cache,
    StorageCategory.logs => categories.logs,
    StorageCategory.models => categories.models,
  };
}

/// 按分类的业务条目类型生成“大小 + 数量”摘要。
String _categoryStatsLabel(
  Translations translations,
  StorageCategoryUsage usage,
) {
  final size = formatByteSize(usage.bytes);
  return switch (usage.category) {
    StorageCategory.chatHistory => translations.storage.sizeAndMessages(
      size: size,
      count: usage.itemCount,
    ),
    StorageCategory.assistant => translations.storage.sizeAndAssistants(
      size: size,
      count: usage.itemCount,
    ),
    _ => translations.storage.sizeAndFiles(size: size, count: usage.itemCount),
  };
}
