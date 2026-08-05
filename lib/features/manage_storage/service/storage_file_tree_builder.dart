import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';

import '../model/storage_file_node.dart';

/// 将本地目录递归构建为 [TreeType]。
abstract final class StorageFileTreeBuilder {
  static TreeType<StorageFileNode> build(
    Directory root, {
    bool expandRoot = true,
  }) {
    return _buildDirectory(root, parent: null, isExpanded: expandRoot);
  }

  static TreeType<StorageFileNode> _buildDirectory(
    Directory directory, {
    required TreeType<StorageFileNode>? parent,
    required bool isExpanded,
  }) {
    final node = TreeType<StorageFileNode>(
      data: StorageFileNode(
        id: directory.path,
        title: p.basename(directory.path),
        path: directory.path,
        isInner: true,
        isExpanded: isExpanded,
      ),
      children: <TreeType<StorageFileNode>>[],
      parent: parent,
    );

    final entities = directory.listSync(followLinks: false)
      ..sort(_compareEntities);

    for (final entity in entities) {
      if (entity is Directory) {
        node.children.add(
          _buildDirectory(entity, parent: node, isExpanded: false),
        );
      } else if (entity is File) {
        node.children.add(_buildFile(entity, parent: node));
      }
    }

    return node;
  }

  static TreeType<StorageFileNode> _buildFile(
    File file, {
    required TreeType<StorageFileNode> parent,
  }) {
    final length = file.existsSync() ? file.lengthSync() : 0;
    return TreeType<StorageFileNode>(
      data: StorageFileNode(
        id: file.path,
        title: p.basename(file.path),
        path: file.path,
        bytes: length,
        isInner: false,
      ),
      children: const <TreeType<StorageFileNode>>[],
      parent: parent,
    );
  }

  static int _compareEntities(FileSystemEntity a, FileSystemEntity b) {
    final aIsDir = a is Directory;
    final bIsDir = b is Directory;
    if (aIsDir != bIsDir) {
      return aIsDir ? -1 : 1;
    }
    return p
        .basename(a.path)
        .toLowerCase()
        .compareTo(p.basename(b.path).toLowerCase());
  }
}
