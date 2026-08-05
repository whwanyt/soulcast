import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/chat_memory_update_service.dart';

part 'chat_memory_update_service.g.dart';

/// 提供无状态的会话长期记忆整理服务。
@Riverpod(keepAlive: true)
ChatMemoryUpdateService chatMemoryUpdateService(Ref ref) {
  return const ChatMemoryUpdateService();
}
