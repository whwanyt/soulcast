import 'package:flute_core/log/log.dart';

import '../api/create_llm_client.dart';
import '../api/llm_client.dart';
import '../model/remote_ai_model.dart';

/// 根据临时凭证创建远端模型查询客户端。
typedef RemoteModelClientFactory =
    LlmClient Function({required String apiKey, required String baseUrl});

/// 使用临时服务商配置拉取远端模型目录。
class RemoteAiModelService {
  const RemoteAiModelService({
    RemoteModelClientFactory clientFactory = _defaultClientFactory,
  }) : this._(clientFactory);

  const RemoteAiModelService._(this._clientFactory);

  final RemoteModelClientFactory _clientFactory;

  Future<List<RemoteAiModel>> fetchModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    final client = _clientFactory(
      apiKey: apiKey.trim(),
      baseUrl: normalizeRemoteModelBaseUrl(baseUrl),
    );
    try {
      return await client.listModels();
    } catch (error, stackTrace) {
      Log.e(
        'RemoteAiModelService fetchModels failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      client.close();
    }
  }
}

/// 规范化模型目录请求使用的服务根地址。
String normalizeRemoteModelBaseUrl(String baseUrl) {
  return baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
}

LlmClient _defaultClientFactory({
  required String apiKey,
  required String baseUrl,
}) {
  return createLlmClientWithApiKey(apiKey: apiKey, baseUrl: baseUrl);
}
