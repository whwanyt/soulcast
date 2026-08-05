import 'package:flute_core/log/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/chat/chat.dart';

part 'chat_info_editor.g.dart';

/// 管理会话详情页可编辑的模型、提示词与长期记忆。
@Riverpod(keepAlive: true)
class ChatInfoEditor extends _$ChatInfoEditor {
  @override
  FutureOr<void> build() {}

  Future<void> saveMemory({
    required String conversationId,
    required String summary,
    required List<ChatMemoryFact> facts,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.saveMemory(
        conversationId: conversationId,
        summary: summary,
        facts: facts,
      );
      Log.d(
        'Chat info memory manually saved: conversationId=$conversationId, '
        'facts=${facts.length}',
        tag: 'Chat',
      );
    });
  }

  Future<void> clearMemory(String conversationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.clearMemory(conversationId);
      Log.d(
        'Chat info memory manually cleared: conversationId=$conversationId',
        tag: 'Chat',
      );
    });
  }

  Future<void> saveConversationSystemPrompt({
    required String conversationId,
    required String? systemPrompt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.saveConversationSystemPrompt(
        conversationId: conversationId,
        systemPrompt: systemPrompt,
      );
      Log.d(
        'Chat conversation system prompt saved: '
        'conversationId=$conversationId',
        tag: 'Chat',
      );
    });
  }

  Future<void> saveConversationWorldBookIds({
    required String conversationId,
    required List<String> worldBookIds,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(chatRepositoryProvider.future);
      repository.setConversationWorldBookIds(
        conversationId: conversationId,
        worldBookIds: worldBookIds,
      );
      Log.d(
        'Chat conversation world books saved: '
        'conversationId=$conversationId, count=${worldBookIds.length}',
        tag: 'Chat',
      );
    });
  }
}
