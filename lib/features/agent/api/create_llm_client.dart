import '../model/chat_settings.dart';
import 'llm_client.dart';
import 'openai_compatible_llm_client.dart';

/// 按供应商 [ChatSettings.apiMode] 创建 [LlmClient]。
LlmClient createLlmClient(ChatSettings settings) {
  return OpenAiCompatibleLlmClient.fromSettings(settings);
}

/// 仅凭 apiKey / baseUrl 创建客户端（用于拉取远程模型列表等）。
LlmClient createLlmClientWithApiKey({
  required String apiKey,
  required String baseUrl,
}) {
  return OpenAiCompatibleLlmClient.withApiKey(apiKey: apiKey, baseUrl: baseUrl);
}
