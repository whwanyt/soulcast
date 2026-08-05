import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/agent/agent.dart';

import '../service/manage_ai_provider_service.dart';

part 'manage_ai_provider_service.g.dart';

/// 提供 AI 服务商管理动作服务。
@Riverpod(keepAlive: true)
ManageAiProviderService manageAiProviderService(Ref ref) {
  return ManageAiProviderService(
    repository: () => ref.read(aiProviderRepositoryProvider.future),
    remoteModelService: () => ref.read(remoteAiModelServiceProvider),
  );
}
