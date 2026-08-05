import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/remote_ai_model_service.dart';

part 'remote_ai_model_service.g.dart';

/// 提供远端模型目录查询服务。
@Riverpod(keepAlive: true)
RemoteAiModelService remoteAiModelService(Ref ref) {
  return const RemoteAiModelService();
}
