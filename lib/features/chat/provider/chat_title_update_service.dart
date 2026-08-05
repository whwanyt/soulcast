import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/chat_title_update_service.dart';

part 'chat_title_update_service.g.dart';

/// 提供无状态的会话标题生成服务。
@Riverpod(keepAlive: true)
ChatTitleUpdateService chatTitleUpdateService(Ref ref) {
  return const ChatTitleUpdateService();
}
