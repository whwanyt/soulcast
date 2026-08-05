import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/shared/storage/image_file_store.dart';

import '../service/manage_character_service.dart';

part 'manage_character_service.g.dart';

/// 提供角色卡管理动作服务。
@Riverpod(keepAlive: true)
ManageCharacterService manageCharacterService(Ref ref) {
  return ManageCharacterService(
    characterRepository: () => ref.read(characterRepositoryProvider.future),
    chatRepository: () => ref.read(chatRepositoryProvider.future),
    avatarStore: const ImageFileStore(fileNamePrefix: 'avatar'),
  );
}
