import 'package:soulcast/entities/ai_provider/ai_provider.dart';

import '../model/chat_settings.dart';

/// 按模型 id 解析 OpenAI 兼容客户端所需的供应商凭证。
///
/// 不包含会话级 systemPrompt / 记忆等聊天编排字段。
ChatSettings? resolveProviderClientSettings({
  required AiProviderRepository repository,
  required String modelId,
}) {
  final model = repository.getModel(modelId);
  if (model == null || !model.isEnabled) {
    return null;
  }

  final provider = repository.getProvider(model.providerId);
  if (provider == null) {
    return null;
  }

  return ChatSettings(
    apiKey: provider.apiKey,
    baseUrl: provider.baseUrl,
    apiPath: provider.apiPath,
    apiMode: provider.apiModeValue,
    backgroundEnabled: provider.usesBackgroundResponse,
    timeout: const Duration(minutes: 10),
    connectTimeout: const Duration(seconds: 30),
    maxRetries: 3,
    model: model.model,
    modelId: model.id,
    modelName: model.name,
    providerId: provider.id,
    providerName: provider.name,
  );
}
