import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/agent/agent.dart';

/// 延迟获取 AI 服务商仓库。
typedef AiProviderRepositoryGetter = Future<AiProviderRepository> Function();

/// 获取远端模型查询服务。
typedef RemoteAiModelServiceGetter = RemoteAiModelService Function();

/// 编排 AI 服务商、模型配置与远端模型导入动作。
class ManageAiProviderService {
  const ManageAiProviderService({
    required this.repository,
    required this.remoteModelService,
  });

  final AiProviderRepositoryGetter repository;
  final RemoteAiModelServiceGetter remoteModelService;

  Future<AiProviderEntity> saveProvider({
    String? providerId,
    required String name,
    required String baseUrl,
    required String apiPath,
    required String apiKey,
    String apiMode = 'chatCompletions',
    bool backgroundEnabled = false,
  }) async {
    final repo = await repository();
    return repo.upsertProvider(
      providerId: providerId,
      name: name,
      baseUrl: baseUrl,
      apiPath: apiPath,
      apiKey: apiKey,
      apiMode: apiMode,
      backgroundEnabled: backgroundEnabled,
    );
  }

  Future<void> deleteProvider(String providerId) async {
    final repo = await repository();
    repo.deleteProvider(providerId);
  }

  Future<void> saveModel({
    String? modelId,
    required String providerId,
    required String name,
    required String model,
    required bool isEnabled,
    List<String> inputFormats = const [],
    List<String> outputFormats = const [],
  }) async {
    final repo = await repository();
    repo.upsertModel(
      modelId: modelId,
      providerId: providerId,
      name: name,
      model: model,
      isEnabled: isEnabled,
      inputFormats: inputFormats,
      outputFormats: outputFormats,
    );
  }

  Future<void> deleteModel(String modelId) async {
    final repo = await repository();
    repo.deleteModel(modelId);
  }

  Future<void> setModelEnabled({
    required String modelId,
    required bool isEnabled,
  }) async {
    final repo = await repository();
    repo.setModelEnabled(modelId: modelId, isEnabled: isEnabled);
  }

  Future<List<RemoteAiModel>> fetchRemoteModels({
    required String baseUrl,
    required String apiKey,
  }) {
    return remoteModelService().fetchModels(baseUrl: baseUrl, apiKey: apiKey);
  }

  /// 返回 `true` 表示已写入；`false` 表示 model id 已存在。
  Future<bool> importRemoteModel({
    required String providerId,
    required RemoteAiModel remoteModel,
  }) async {
    final modelId = remoteModel.id.trim();
    if (modelId.isEmpty) {
      return false;
    }
    final repo = await repository();
    final alreadyExists = repo
        .getModels(providerId: providerId)
        .any((model) => model.model.trim() == modelId);
    if (alreadyExists) {
      return false;
    }
    repo.upsertModel(
      modelId: null,
      providerId: providerId,
      name: modelId,
      model: modelId,
      isEnabled: true,
      inputFormats: const [],
      outputFormats: const [],
    );
    return true;
  }
}
