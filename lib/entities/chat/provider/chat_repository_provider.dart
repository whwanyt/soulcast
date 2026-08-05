import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../chat_conversation_entity.dart';
import '../model/chat_conversation_memory.dart';
import '../model/chat_conversation_message.dart';
import '../repository/chat_repository.dart';
import 'isar_provider.dart';

part 'chat_repository_provider.g.dart';

/// 提供会话、消息与记忆的共享仓库。
@Riverpod(keepAlive: true)
Future<ChatRepository> chatRepository(Ref ref) async {
  final isar = await ref.watch(chatIsarProvider.future);
  return ChatRepository(isar);
}

/// 监听全部会话摘要。
@Riverpod(keepAlive: true)
Stream<List<ChatConversationEntity>> chatConversations(Ref ref) async* {
  final repository = await ref.watch(chatRepositoryProvider.future);
  yield* repository.watchConversations();
}

/// 监听指定会话的消息列表。
@Riverpod(keepAlive: true)
Stream<List<ChatConversationMessage>> chatMessages(
  Ref ref,
  String conversationId,
) async* {
  final repository = await ref.watch(chatRepositoryProvider.future);
  yield* repository.watchMessages(conversationId);
}

/// 监听指定会话的长期记忆。
@Riverpod(keepAlive: true)
Stream<ChatConversationMemory> chatConversationMemory(
  Ref ref,
  String conversationId,
) async* {
  final repository = await ref.watch(chatRepositoryProvider.future);
  yield* repository.watchMemory(conversationId);
}
