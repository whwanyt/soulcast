import 'package:isar_plus/isar_plus.dart';

import '../ai_model_entity.dart';
import '../ai_provider_entity.dart';
import '../model/ai_provider_api_mode.dart';

/// AI 服务商及其模型配置的 Isar 仓库。
///
/// 服务商与模型共享一个数据库，删除服务商时会在同一事务中级联删除模型。
class AiProviderRepository {
  const AiProviderRepository(this._isar);

  final Isar _isar;

  List<AiProviderEntity> getProviders() {
    return _sortProviders(
      _isar.collection<String, AiProviderEntity>().where().findAll(),
    );
  }

  Stream<List<AiProviderEntity>> watchProviders() {
    return _isar
        .collection<String, AiProviderEntity>()
        .where()
        .watch(fireImmediately: true)
        .map(_sortProviders);
  }

  AiProviderEntity? getProvider(String providerId) {
    return _isar.collection<String, AiProviderEntity>().get(providerId);
  }

  AiProviderEntity upsertProvider({
    String? providerId,
    required String name,
    required String baseUrl,
    required String apiPath,
    required String apiKey,
    String apiMode = 'chatCompletions',
    bool backgroundEnabled = false,
  }) {
    final now = DateTime.now();
    final id = providerId ?? createProviderId();
    final normalizedApiMode = parseAiProviderApiMode(apiMode).name;
    // background 仅对 Responses 有意义；Completions 强制关闭。
    final normalizedBackground =
        normalizedApiMode == AiProviderApiMode.responses.name &&
        backgroundEnabled;
    late AiProviderEntity provider;
    _isar.write((isar) {
      final providers = isar.collection<String, AiProviderEntity>();
      final existing = providers.get(id);
      provider =
          existing?.copyWith(
            name: name.trim(),
            baseUrl: _normalizeBaseUrl(baseUrl),
            apiPath: _normalizeApiPath(apiPath),
            apiKey: apiKey.trim(),
            apiMode: normalizedApiMode,
            backgroundEnabled: normalizedBackground,
            updatedAt: now,
          ) ??
          AiProviderEntity(
            id: id,
            name: name.trim(),
            baseUrl: _normalizeBaseUrl(baseUrl),
            apiPath: _normalizeApiPath(apiPath),
            apiKey: apiKey.trim(),
            apiMode: normalizedApiMode,
            backgroundEnabled: normalizedBackground,
            createdAt: now,
            updatedAt: now,
          );
      providers.put(provider);
    });
    return provider;
  }

  bool deleteProvider(String providerId) {
    var deleted = false;
    _isar.write((isar) {
      final providers = isar.collection<String, AiProviderEntity>();
      deleted = providers.delete(providerId);
      if (!deleted) {
        return;
      }
      // 模型没有独立存在的业务意义，随所属服务商一起删除。
      isar
          .collection<String, AiModelEntity>()
          .where()
          .providerIdEqualTo(providerId)
          .deleteAll();
    });
    return deleted;
  }

  List<AiModelEntity> getModels({String? providerId}) {
    final models = providerId == null
        ? _isar.collection<String, AiModelEntity>().where().findAll()
        : _isar
              .collection<String, AiModelEntity>()
              .where()
              .providerIdEqualTo(providerId)
              .findAll();
    return _sortModels(models);
  }

  Stream<List<AiModelEntity>> watchModels({String? providerId}) {
    final stream = providerId == null
        ? _isar.collection<String, AiModelEntity>().where().watch(
            fireImmediately: true,
          )
        : _isar
              .collection<String, AiModelEntity>()
              .where()
              .providerIdEqualTo(providerId)
              .watch(fireImmediately: true);
    return stream.map(_sortModels);
  }

  AiModelEntity? getModel(String modelId) {
    return _isar.collection<String, AiModelEntity>().get(modelId);
  }

  AiModelEntity upsertModel({
    String? modelId,
    required String providerId,
    required String name,
    required String model,
    bool isEnabled = true,
    List<String> inputFormats = const [],
    List<String> outputFormats = const [],
  }) {
    final now = DateTime.now();
    final id = modelId ?? createModelId();
    final normalizedInputFormats = _normalizeFormatTags(inputFormats);
    final normalizedOutputFormats = _normalizeFormatTags(outputFormats);
    late AiModelEntity aiModel;
    _isar.write((isar) {
      final models = isar.collection<String, AiModelEntity>();
      final existing = models.get(id);
      aiModel =
          existing?.copyWith(
            providerId: providerId,
            name: name.trim(),
            model: model.trim(),
            isEnabled: isEnabled,
            inputFormats: normalizedInputFormats,
            outputFormats: normalizedOutputFormats,
            updatedAt: now,
          ) ??
          AiModelEntity(
            id: id,
            providerId: providerId,
            name: name.trim(),
            model: model.trim(),
            isEnabled: isEnabled,
            inputFormats: normalizedInputFormats,
            outputFormats: normalizedOutputFormats,
            createdAt: now,
            updatedAt: now,
          );
      models.put(aiModel);
    });
    return aiModel;
  }

  void setModelEnabled({required String modelId, required bool isEnabled}) {
    _isar.write((isar) {
      final models = isar.collection<String, AiModelEntity>();
      final existing = models.get(modelId);
      if (existing == null || existing.isEnabled == isEnabled) {
        return;
      }
      models.put(existing.copyWith(isEnabled: isEnabled));
    });
  }

  bool deleteModel(String modelId) {
    var deleted = false;
    _isar.write((isar) {
      deleted = isar.collection<String, AiModelEntity>().delete(modelId);
    });
    return deleted;
  }

  String createProviderId() {
    return 'provider_${DateTime.now().microsecondsSinceEpoch}';
  }

  String createModelId() {
    return 'model_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _normalizeBaseUrl(String baseUrl) {
    final normalized = baseUrl.trim();
    if (normalized.endsWith('/')) {
      return normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  String _normalizeApiPath(String apiPath) {
    final normalized = apiPath.trim();
    if (normalized.isEmpty || normalized == '/') {
      return '';
    }
    final withLeadingSlash = normalized.startsWith('/')
        ? normalized
        : '/$normalized';
    if (withLeadingSlash.endsWith('/')) {
      return withLeadingSlash.substring(0, withLeadingSlash.length - 1);
    }
    return withLeadingSlash;
  }

  List<String> _normalizeFormatTags(List<String> tags) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final tag in tags) {
      final value = tag.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      normalized.add(value);
    }
    return normalized;
  }
}

List<AiProviderEntity> _sortProviders(List<AiProviderEntity> providers) {
  return [...providers]..sort((first, second) {
    return second.updatedAt.compareTo(first.updatedAt);
  });
}

List<AiModelEntity> _sortModels(List<AiModelEntity> models) {
  return [...models]..sort((first, second) {
    if (first.isEnabled != second.isEnabled) {
      return first.isEnabled ? -1 : 1;
    }
    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  });
}
