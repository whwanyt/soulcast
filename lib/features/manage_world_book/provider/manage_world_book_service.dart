import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/world_book/world_book.dart';

import '../service/manage_world_book_service.dart';

part 'manage_world_book_service.g.dart';

/// 提供世界书管理动作服务。
@Riverpod(keepAlive: true)
ManageWorldBookService manageWorldBookService(Ref ref) {
  return ManageWorldBookService(
    worldBookRepository: () => ref.read(worldBookRepositoryProvider.future),
    characterRepository: () => ref.read(characterRepositoryProvider.future),
    chatRepository: () => ref.read(chatRepositoryProvider.future),
  );
}
