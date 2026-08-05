import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';
import 'package:soulcast/shared/storage/app_directories.dart';
import 'package:soulcast/shared/utils/directory_usage.dart';

import '../model/storage_category.dart';
import '../model/storage_file_node.dart';
import '../model/storage_usage.dart';
import 'storage_file_tree_builder.dart';
import 'storage_usage_scanner.dart';

/// 存储空间扫描与清理动作。
class ManageStorageService {
  ManageStorageService({
    required this.scanner,
    required this.chatRepository,
    required this.characterRepository,
    required this.speechModelRepository,
  });

  final StorageUsageScanner scanner;
  final Future<ChatRepository> Function() chatRepository;
  final Future<CharacterRepository> Function() characterRepository;
  final Future<SpeechModelRepository> Function() speechModelRepository;

  Future<StorageUsageSnapshot> scan() => scanner.scan();

  Future<void> clearCategory(StorageCategory category) async {
    switch (category) {
      case StorageCategory.images:
      case StorageCategory.cache:
      case StorageCategory.logs:
        final directory = await scanner.directoryFor(category);
        await clearDirectoryContents(directory);
      case StorageCategory.files:
        final directory = await scanner.directoryFor(category);
        await clearDirectoryContents(directory);
        final attachments = (await AppDirectories.resolve()).chatAttachments;
        await clearDirectoryContents(attachments);
      case StorageCategory.chatHistory:
        final repo = await chatRepository();
        repo.deleteAllConversations();
      case StorageCategory.assistant:
        final chatRepo = await chatRepository();
        final characterRepo = await characterRepository();
        for (final character in characterRepo.getCharacters()) {
          chatRepo.deleteConversationsByCharacter(character.id);
          characterRepo.deleteCharacter(character.id);
        }
      case StorageCategory.models:
        final directory = await scanner.directoryFor(category);
        await clearDirectoryContents(directory);
        final speechRepo = await speechModelRepository();
        speechRepo.deleteAll();
    }
  }

  Future<TreeType<StorageFileNode>?> listCategoryFileTree(
    StorageCategory category,
  ) async {
    switch (category) {
      case StorageCategory.images:
      case StorageCategory.files:
      case StorageCategory.cache:
      case StorageCategory.logs:
      case StorageCategory.models:
        final directory = await scanner.directoryFor(category);
        if (!directory.existsSync()) {
          return null;
        }
        return StorageFileTreeBuilder.build(directory);
      case StorageCategory.chatHistory:
      case StorageCategory.assistant:
        return null;
    }
  }
}
