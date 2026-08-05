import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:soulcast/shared/storage/app_directories.dart';

/// 删除 Agent 文件库中的本地文件。
class AgentLibraryDeleter {
  const AgentLibraryDeleter();

  /// 删除 [path] 指向的文件；仅允许位于 [AppDirectories.agent] 目录内。
  Future<void> delete(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(path, 'path', 'must not be empty');
    }

    final directories = await AppDirectories.resolve();
    final root = p.normalize(directories.agent.absolute.path);
    final target = p.normalize(File(trimmed).absolute.path);
    final rootPrefix = root.endsWith(p.separator)
        ? root
        : '$root${p.separator}';
    if (target != root && !target.startsWith(rootPrefix)) {
      throw ArgumentError.value(
        path,
        'path',
        'must be inside AppDirectories.agent',
      );
    }

    final file = File(target);
    if (!file.existsSync()) {
      return;
    }
    await file.delete();
  }
}
