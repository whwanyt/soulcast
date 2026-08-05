import 'dart:io';
import 'dart:math' as math;

/// 目录占用统计结果。
class DirectoryUsage {
  const DirectoryUsage({required this.bytes, required this.fileCount});

  static const empty = DirectoryUsage(bytes: 0, fileCount: 0);

  final int bytes;
  final int fileCount;

  DirectoryUsage operator +(DirectoryUsage other) {
    return DirectoryUsage(
      bytes: bytes + other.bytes,
      fileCount: fileCount + other.fileCount,
    );
  }
}

/// 递归统计目录内文件占用。
Future<DirectoryUsage> measureDirectoryUsage(Directory directory) async {
  if (!directory.existsSync()) {
    return DirectoryUsage.empty;
  }

  var bytes = 0;
  var fileCount = 0;

  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }
    try {
      bytes += entity.lengthSync();
      fileCount += 1;
    } on FileSystemException {
      // 跳过无法读取的文件。
    }
  }

  return DirectoryUsage(bytes: bytes, fileCount: fileCount);
}

/// 删除目录下全部内容，保留目录本身。
Future<void> clearDirectoryContents(Directory directory) async {
  if (!directory.existsSync()) {
    return;
  }

  await for (final entity in directory.list(followLinks: false)) {
    try {
      await entity.delete(recursive: true);
    } on FileSystemException {
      // 跳过无法删除的条目。
    }
  }
}

/// 将字节格式化为可读大小（如 `122.0 KB`）。
String formatByteSize(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  final unitIndex = math.min(
    (math.log(bytes) / math.log(1024)).floor(),
    units.length - 1,
  );
  final value = bytes / math.pow(1024, unitIndex);
  final precision = unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
}
