import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:soulcast/shared/storage/app_directories.dart';

import '../model/agent_library_item.dart';

/// 扫描 [AppDirectories.agent] 下的图片与文件。
class AgentLibraryScanner {
  const AgentLibraryScanner();

  static const _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.heic',
    '.heif',
  };

  Future<List<AgentLibraryItem>> scan() async {
    final directories = await AppDirectories.resolve();
    final root = directories.agent;
    if (!root.existsSync()) {
      return const [];
    }

    final items = <AgentLibraryItem>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final name = p.basename(entity.path);
      if (name.isEmpty || name.startsWith('.')) {
        continue;
      }

      try {
        final stat = entity.statSync();
        final extension = p.extension(name).toLowerCase();
        final kind = _imageExtensions.contains(extension)
            ? AgentLibraryItemKind.image
            : AgentLibraryItemKind.file;
        items.add(
          AgentLibraryItem(
            path: entity.path,
            name: name,
            bytes: stat.size,
            modifiedAt: stat.modified,
            kind: kind,
          ),
        );
      } on FileSystemException {
        // 跳过无法读取的文件。
      }
    }

    items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items;
  }
}
