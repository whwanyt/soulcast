import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/chat_service.dart';

part 'chat_service.g.dart';

/// 组装聊天请求、工具循环与流式响应编排服务。
@Riverpod(keepAlive: true)
ChatService chatService(Ref ref) {
  return const ChatService();
}
