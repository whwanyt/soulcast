import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';

import '../model/storage_category.dart';
import '../model/storage_file_node.dart';
import '../model/storage_usage.dart';
import '../service/manage_storage_service.dart';
import '../service/storage_usage_scanner.dart';

part 'manage_storage_service.g.dart';

/// 组装存储扫描与清理服务所需的实体仓库。
@Riverpod(keepAlive: true)
ManageStorageService manageStorageService(Ref ref) {
  Future<ChatRepository> chatRepository() =>
      ref.read(chatRepositoryProvider.future);
  Future<CharacterRepository> characterRepository() =>
      ref.read(characterRepositoryProvider.future);
  Future<SpeechModelRepository> speechModelRepository() =>
      ref.read(speechModelRepositoryProvider.future);

  return ManageStorageService(
    scanner: StorageUsageScanner(
      chatRepository: chatRepository,
      characterRepository: characterRepository,
      speechModelRepository: speechModelRepository,
    ),
    chatRepository: chatRepository,
    characterRepository: characterRepository,
    speechModelRepository: speechModelRepository,
  );
}

/// 管理存储占用快照，并在清理后重新扫描。
@Riverpod(keepAlive: true)
class StorageUsage extends _$StorageUsage {
  @override
  Future<StorageUsageSnapshot> build() {
    return ref.read(manageStorageServiceProvider).scan();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> clearCategory(StorageCategory category) async {
    await ref.read(manageStorageServiceProvider).clearCategory(category);
    await refresh();
  }

  Future<TreeType<StorageFileNode>?> listCategoryFileTree(
    StorageCategory category,
  ) {
    return ref
        .read(manageStorageServiceProvider)
        .listCategoryFileTree(category);
  }
}
