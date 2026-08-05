import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/world_book/world_book.dart';

/// 延迟获取世界书仓库。
typedef WorldBookRepositoryGetter = Future<WorldBookRepository> Function();

/// 延迟获取角色仓库。
typedef CharacterRepositoryGetter = Future<CharacterRepository> Function();

/// 延迟获取聊天仓库。
typedef ChatRepositoryGetter = Future<ChatRepository> Function();

/// 编排世界书与条目的保存、删除及引用清理。
class ManageWorldBookService {
  const ManageWorldBookService({
    required this.worldBookRepository,
    required this.characterRepository,
    required this.chatRepository,
  });

  final WorldBookRepositoryGetter worldBookRepository;
  final CharacterRepositoryGetter characterRepository;
  final ChatRepositoryGetter chatRepository;

  Future<WorldBookEntity> saveWorldBook({
    String? worldBookId,
    required String name,
    String description = '',
    int scanDepth = 50,
    int tokenBudget = 2000,
    bool recursiveScanning = false,
  }) async {
    final repo = await worldBookRepository();
    return repo.upsertWorldBook(
      worldBookId: worldBookId,
      name: name,
      description: description,
      scanDepth: scanDepth,
      tokenBudget: tokenBudget,
      recursiveScanning: recursiveScanning,
    );
  }

  /// 从角色卡内嵌 character_book 创建独立世界书。
  Future<WorldBookEntity> createFromCardBook(WorldBook snapshot) async {
    final repo = await worldBookRepository();
    final id = snapshot.id.trim().isEmpty
        ? repo.createWorldBookId()
        : snapshot.id;
    final withIds = snapshot.copyWith(
      id: id,
      entries: snapshot.entries
          .map(
            (entry) => entry.copyWith(
              id: entry.id.trim().isEmpty ? repo.createEntryId() : entry.id,
              worldBookId: id,
            ),
          )
          .toList(growable: false),
    );
    return repo.replaceWorldBookSnapshot(withIds);
  }

  Future<WorldBookEntryEntity> saveEntry(WorldBookEntry entry) async {
    final repo = await worldBookRepository();
    final id = entry.id.trim().isEmpty ? repo.createEntryId() : entry.id;
    return repo.upsertEntry(entry.copyWith(id: id));
  }

  Future<void> deleteEntry(String entryId) async {
    final repo = await worldBookRepository();
    repo.deleteEntry(entryId);
  }

  Future<void> deleteWorldBook(String worldBookId) async {
    final characterRepo = await characterRepository();
    characterRepo.clearWorldBookReferences(worldBookId);
    final chatRepo = await chatRepository();
    chatRepo.clearWorldBookReferences(worldBookId);
    final worldRepo = await worldBookRepository();
    worldRepo.deleteWorldBook(worldBookId);
  }

  Future<WorldBook?> getSnapshot(String worldBookId) async {
    final repo = await worldBookRepository();
    return repo.getWorldBookSnapshot(worldBookId);
  }
}
