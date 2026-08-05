import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../character_entity.dart';
import '../repository/character_repository.dart';
import 'isar_provider.dart';

part 'character_repository_provider.g.dart';

/// 提供角色卡仓库。
@Riverpod(keepAlive: true)
Future<CharacterRepository> characterRepository(Ref ref) async {
  final isar = await ref.watch(characterIsarProvider.future);
  return CharacterRepository(isar);
}

/// 监听按最近更新时间排序的全部角色卡。
@Riverpod(keepAlive: true)
Stream<List<CharacterEntity>> characters(Ref ref) async* {
  final repository = await ref.watch(characterRepositoryProvider.future);
  yield* repository.watchCharacters();
}
