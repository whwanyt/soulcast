import 'package:flutter/material.dart';
import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';
import 'package:soulcast/features/manage_storage/manage_storage.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/utils/directory_usage.dart';

/// 存储分类的可展开文件树。
///
/// 根节点由存储管理 feature 构建，本组件只负责递归展示与维护节点展开状态。
class StorageFileTree extends StatelessWidget {
  const StorageFileTree({required this.tree, super.key});

  /// 待展示的文件树根节点。
  final TreeType<StorageFileNode> tree;

  @override
  Widget build(BuildContext context) {
    return StorageFileTreeNode(tree);
  }
}

/// 递归渲染一个文件树节点及其子节点。
class StorageFileTreeNode extends StatefulWidget {
  const StorageFileTreeNode(this.tree, {super.key});

  /// 当前层级对应的目录或文件节点。
  final TreeType<StorageFileNode> tree;

  @override
  State<StorageFileTreeNode> createState() => _StorageFileTreeNodeState();
}

class _StorageFileTreeNodeState extends State<StorageFileTreeNode>
    with SingleTickerProviderStateMixin, ExpandableTreeMixin<StorageFileNode> {
  /// 将展开图标从朝右的折叠态旋转至朝下的展开态。
  final Tween<double> _turnsTween = Tween<double>(begin: -0.25, end: 0.0);

  @override
  void initState() {
    super.initState();
    initTree();
    initRotationController();
    if (tree.data.isExpanded) {
      rotationController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant StorageFileTreeNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tree != widget.tree) {
      // 父级换入新扫描结果时，同时校准 mixin 持有的节点和动画进度。
      tree = widget.tree;
      if (tree.data.isExpanded) {
        rotationController.value = 1;
      } else {
        rotationController.value = 0;
      }
    }
  }

  @override
  void initTree() {
    tree = widget.tree;
  }

  @override
  void initRotationController() {
    rotationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    disposeRotationController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildView();

  /// 构建当前节点行；只有目录节点可以切换展开状态。
  @override
  Widget buildNode() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDirectory = tree.data.isInner;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: isDirectory ? updateStateToggleExpansion : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: isDirectory
                    ? RotationTransition(
                        turns: _turnsTween.animate(rotationController),
                        child: Icon(
                          Icons.expand_more,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Icon(
                isDirectory
                    ? (tree.data.isExpanded
                          ? Icons.folder_open_outlined
                          : Icons.folder_outlined)
                    : Icons.insert_drive_file_outlined,
                size: 20,
                color: isDirectory
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDirectory
                      ? '${tree.data.title} (${tree.children.length})'
                      : tree.data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ),
              if (!isDirectory) ...[
                const SizedBox(width: 8),
                Text(
                  formatByteSize(tree.data.bytes),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建随展开动画显隐的子节点区域。
  @override
  Widget buildChildrenNodes({
    EdgeInsets? padding = const EdgeInsets.only(left: 16, top: 6),
  }) {
    return SizeTransition(
      sizeFactor: rotationController,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          children: [
            for (final child in generateChildrenNodesWidget(tree.children))
              Padding(padding: const EdgeInsets.only(bottom: 6), child: child),
          ],
        ),
      ),
    );
  }

  /// 为每个子节点递归创建独立的展开状态组件。
  @override
  List<Widget> generateChildrenNodesWidget(
    List<TreeType<StorageFileNode>> children,
  ) {
    return List.generate(
      children.length,
      (index) => StorageFileTreeNode(children[index]),
    );
  }

  /// 在一次 setState 中同步节点展开标记与旋转动画。
  @override
  void updateStateToggleExpansion() => setState(toggleExpansion);
}
