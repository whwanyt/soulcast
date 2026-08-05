import 'dart:typed_data';

import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/shared/storage/image_file_store.dart';

/// 延迟获取角色仓库。
typedef CharacterRepositoryGetter = Future<CharacterRepository> Function();

/// 延迟获取聊天仓库。
typedef ChatRepositoryGetter = Future<ChatRepository> Function();

/// 编排角色卡保存、收藏与级联删除动作。
class ManageCharacterService {
  const ManageCharacterService({
    required this.characterRepository,
    required this.chatRepository,
    required this.avatarStore,
  });

  final CharacterRepositoryGetter characterRepository;
  final ChatRepositoryGetter chatRepository;
  final ImageFileStore avatarStore;

  Future<Uri> importLocalAvatar(String path) {
    return avatarStore.importLocalImage(path);
  }

  Future<Uri> saveAvatarBytes(Uint8List bytes) {
    return avatarStore.saveBytes(bytes);
  }

  Future<Uri> saveAvatarFromUrl(String url) {
    return avatarStore.saveFromUrl(url);
  }

  Future<CharacterEntity> saveCharacter({
    String? characterId,
    required String name,
    String? avatarUrl,
    required String description,
    required String personality,
    required String speechStyle,
    required String appearance,
    required String scenario,
    required List<String> greetings,
    required String exampleDialogues,
    required String hardConstraints,
    List<String> tags = const [],
    String creator = '',
    String creatorNotes = '',
    String characterVersion = '',
    String cardSystemPrompt = '',
    String postHistoryInstructions = '',
  }) async {
    final repo = await characterRepository();
    return repo.upsertCharacter(
      characterId: characterId,
      name: name,
      avatarUrl: avatarUrl,
      description: description,
      personality: personality,
      speechStyle: speechStyle,
      appearance: appearance,
      scenario: scenario,
      greetings: greetings,
      exampleDialogues: exampleDialogues,
      hardConstraints: hardConstraints,
      tags: tags,
      creator: creator,
      creatorNotes: creatorNotes,
      characterVersion: characterVersion,
      cardSystemPrompt: cardSystemPrompt,
      postHistoryInstructions: postHistoryInstructions,
    );
  }

  Future<CharacterEntity?> setWorldBookBindings({
    required String characterId,
    String? primaryWorldBookId,
    required List<String> extraWorldBookIds,
  }) async {
    final repo = await characterRepository();
    return repo.setWorldBookBindings(
      characterId: characterId,
      primaryWorldBookId: primaryWorldBookId,
      extraWorldBookIds: extraWorldBookIds,
    );
  }

  Future<void> setFavorite({
    required String characterId,
    required bool isFavorite,
  }) async {
    final repo = await characterRepository();
    repo.setCharacterFavorite(characterId: characterId, isFavorite: isFavorite);
  }

  /// 删除角色并级联删除其所有关联会话（含消息和记忆）。
  Future<void> deleteCharacter(String characterId) async {
    final chatRepo = await chatRepository();
    chatRepo.deleteConversationsByCharacter(characterId);
    final characterRepo = await characterRepository();
    characterRepo.deleteCharacter(characterId);
  }
}
