import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repository/world_book_repository.dart';
import '../world_book_entity.dart';
import '../world_book_entry_entity.dart';
import 'isar_provider.dart';

part 'world_book_repository_provider.g.dart';

/// 提供世界书仓库。
@Riverpod(keepAlive: true)
Future<WorldBookRepository> worldBookRepository(Ref ref) async {
  final isar = await ref.watch(worldBookIsarProvider.future);
  return WorldBookRepository(isar);
}

/// 监听全部世界书。
@Riverpod(keepAlive: true)
Stream<List<WorldBookEntity>> worldBooks(Ref ref) async* {
  final repository = await ref.watch(worldBookRepositoryProvider.future);
  yield* repository.watchWorldBooks();
}

/// 监听指定世界书的条目。
@Riverpod(keepAlive: true)
Stream<List<WorldBookEntryEntity>> worldBookEntries(
  Ref ref,
  String worldBookId,
) async* {
  final repository = await ref.watch(worldBookRepositoryProvider.future);
  yield* repository.watchEntries(worldBookId);
}
