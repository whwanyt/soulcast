import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';

/// 存储分类目录树节点（目录为 inner，文件为 leaf）。
class StorageFileNode extends AbsNodeType {
  StorageFileNode({
    required super.id,
    required super.title,
    required this.path,
    this.bytes = 0,
    super.isInner = true,
    super.isExpanded = false,
  });

  final String path;
  final int bytes;

  @override
  T clone<T extends AbsNodeType>() {
    final cloned =
        StorageFileNode(
            id: id,
            title: title,
            path: path,
            bytes: bytes,
            isInner: isInner,
            isExpanded: isExpanded,
          )
          ..isUnavailable = isUnavailable
          ..isChosen = isChosen
          ..isFavorite = isFavorite
          ..isShowedInSearching = isShowedInSearching
          ..isBlurred = isBlurred;
    return cloned as T;
  }
}
