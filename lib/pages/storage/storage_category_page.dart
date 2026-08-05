import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/manage_storage/manage_storage.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/storage/widget/storage_category_style.dart';
import 'package:soulcast/pages/storage/widget/storage_file_tree.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/utils/directory_usage.dart';

/// 单个存储分类的详情与清理页面。
///
/// 页面订阅最新占用快照；完成清理后，概览信息和文件列表会随快照一起刷新。
class StorageCategoryPage extends ConsumerWidget {
  const StorageCategoryPage({required this.category, super.key});

  /// 路由传入的 [StorageCategory.name]。
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    // 路由参数异常时仍提供可操作页面，避免构建阶段因未知分类中断。
    final resolved =
        StorageCategory.tryParse(category) ?? StorageCategory.cache;
    final usageAsync = ref.watch(storageUsageProvider);
    final title = _categoryLabel(translations, resolved);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: usageAsync.when(
          data: (snapshot) {
            final usage = snapshot.usageOf(resolved);
            return StorageCategoryBody(category: resolved, usage: usage);
          },
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

/// 分类详情的数据态内容。
///
/// 使用 StatefulWidget 仅维护清理动作的进行中状态，业务数据仍由 provider 管理。
class StorageCategoryBody extends ConsumerStatefulWidget {
  const StorageCategoryBody({
    required this.category,
    required this.usage,
    super.key,
  });

  /// 当前展示的存储分类。
  final StorageCategory category;

  /// 当前分类在最新扫描快照中的占用信息。
  final StorageCategoryUsage usage;

  @override
  ConsumerState<StorageCategoryBody> createState() =>
      _StorageCategoryBodyState();
}

class _StorageCategoryBodyState extends ConsumerState<StorageCategoryBody> {
  var _clearing = false;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final description = _categoryDescription(translations, widget.category);
    final stats = _categoryStatsLabel(translations, widget.usage);
    final canClear = widget.category.canClear && !widget.usage.isEmpty;

    final showsFileList = _showsFileList(widget.category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadii.xs),
                          boxShadow: AppShadows.soft(colorScheme.shadow),
                        ),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            StorageCategoryStyle.icon(widget.category),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _categoryLabel(translations, widget.category),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: !canClear || _clearing ? null : _confirmAndClear,
            child: _clearing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    translations.storage.clearCategory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (showsFileList) ...[
            const SizedBox(height: 20),
            Text(
              translations.storage.fileList,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder(
                // 占用快照变化时重新创建 FutureBuilder，确保清理后重扫文件树。
                key: ValueKey(
                  '${widget.category.name}-${widget.usage.bytes}-'
                  '${widget.usage.itemCount}',
                ),
                future: ref
                    .read(storageUsageProvider.notifier)
                    .listCategoryFileTree(widget.category),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        translations.storage.loadFailed(
                          error: snapshot.error.toString(),
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  final tree = snapshot.data;
                  if (tree == null || tree.children.isEmpty) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        translations.storage.emptyCategory,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    child: StorageFileTree(tree: tree),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 二次确认后清理当前分类，并向用户反馈执行结果。
  Future<void> _confirmAndClear() async {
    final translations = context.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            translations.storage.clearConfirmTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(
            _clearConfirmMessage(translations, widget.category),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(translations.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(translations.common.clear),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _clearing = true);
    try {
      await ref
          .read(storageUsageProvider.notifier)
          .clearCategory(widget.category);
      if (widget.category == StorageCategory.chatHistory ||
          widget.category == StorageCategory.assistant) {
        // 清理会话相关数据后同步重建运行态，避免继续持有已删除的当前会话。
        await ref
            .read(chatProvider.notifier)
            .restoreInitialConversation(force: true);
      }
      if (!mounted) {
        return;
      }
      await SmartDialog.showToast(translations.storage.clearSuccess);
    } catch (error) {
      if (!mounted) {
        return;
      }
      await SmartDialog.showToast(
        translations.storage.clearFailed(error: error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }
}

/// 判断分类是否有可直接浏览的本地文件目录树。
bool _showsFileList(StorageCategory category) {
  return switch (category) {
    StorageCategory.images ||
    StorageCategory.files ||
    StorageCategory.cache ||
    StorageCategory.logs ||
    StorageCategory.models => true,
    StorageCategory.chatHistory || StorageCategory.assistant => false,
  };
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

/// 返回当前分类的数据来源与清理影响说明。
String _categoryDescription(
  Translations translations,
  StorageCategory category,
) {
  final descriptions = translations.storage.categoryDescriptions;
  return switch (category) {
    StorageCategory.images => descriptions.images,
    StorageCategory.files => descriptions.files,
    StorageCategory.chatHistory => descriptions.chatHistory,
    StorageCategory.assistant => descriptions.assistant,
    StorageCategory.cache => descriptions.cache,
    StorageCategory.logs => descriptions.logs,
    StorageCategory.models => descriptions.models,
  };
}

/// 返回当前分类对应的清理确认提示。
String _clearConfirmMessage(
  Translations translations,
  StorageCategory category,
) {
  final messages = translations.storage.clearConfirmMessages;
  return switch (category) {
    StorageCategory.images => messages.images,
    StorageCategory.files => messages.files,
    StorageCategory.chatHistory => messages.chatHistory,
    StorageCategory.assistant => messages.assistant,
    StorageCategory.cache => messages.cache,
    StorageCategory.logs => messages.logs,
    StorageCategory.models => messages.models,
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
