import 'dart:io';

import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';
import 'package:soulcast/shared/storage/app_directories.dart';
import 'package:soulcast/shared/utils/directory_usage.dart';

import '../model/storage_category.dart';
import '../model/storage_usage.dart';

/// 扫描本地目录与数据库占用。
class StorageUsageScanner {
  const StorageUsageScanner({
    required this.chatRepository,
    required this.characterRepository,
    required this.speechModelRepository,
  });

  final Future<ChatRepository> Function() chatRepository;
  final Future<CharacterRepository> Function() characterRepository;
  final Future<SpeechModelRepository> Function() speechModelRepository;

  Future<StorageUsageSnapshot> scan() async {
    final directories = await AppDirectories.resolve();

    final images = await measureDirectoryUsage(directories.generatedImages);
    final files =
        await measureDirectoryUsage(directories.files) +
        await measureDirectoryUsage(directories.chatAttachments);
    final isar = await measureDirectoryUsage(directories.isar);
    final logs = await measureDirectoryUsage(directories.logs);
    final cache = await measureDirectoryUsage(directories.cache);
    final models = await measureDirectoryUsage(directories.models);

    final chatRepo = await chatRepository();
    final characterRepo = await characterRepository();
    final speechRepo = await speechModelRepository();

    return StorageUsageSnapshot(
      scannedAt: DateTime.now(),
      categories: [
        StorageCategoryUsage(
          category: StorageCategory.images,
          bytes: images.bytes,
          itemCount: images.fileCount,
        ),
        StorageCategoryUsage(
          category: StorageCategory.files,
          bytes: files.bytes,
          itemCount: files.fileCount,
        ),
        StorageCategoryUsage(
          category: StorageCategory.chatHistory,
          bytes: isar.bytes,
          itemCount: chatRepo.countMessages(),
        ),
        StorageCategoryUsage(
          category: StorageCategory.assistant,
          bytes: 0,
          itemCount: characterRepo.getCharacters().length,
        ),
        StorageCategoryUsage(
          category: StorageCategory.cache,
          bytes: cache.bytes,
          itemCount: cache.fileCount,
        ),
        StorageCategoryUsage(
          category: StorageCategory.logs,
          bytes: logs.bytes,
          itemCount: logs.fileCount,
        ),
        StorageCategoryUsage(
          category: StorageCategory.models,
          bytes: models.bytes,
          itemCount: speechRepo.getAll().length,
        ),
      ],
    );
  }

  Future<Directory> directoryFor(StorageCategory category) async {
    final directories = await AppDirectories.resolve();
    return switch (category) {
      StorageCategory.images => directories.generatedImages,
      StorageCategory.files => directories.files,
      StorageCategory.chatHistory => directories.isar,
      StorageCategory.assistant => directories.isar,
      StorageCategory.cache => directories.cache,
      StorageCategory.logs => directories.logs,
      StorageCategory.models => directories.models,
    };
  }
}
