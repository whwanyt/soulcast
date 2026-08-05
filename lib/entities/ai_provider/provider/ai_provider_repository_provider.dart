import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../ai_model_entity.dart';
import '../ai_provider_entity.dart';
import '../repository/ai_provider_repository.dart';
import 'isar_provider.dart';

part 'ai_provider_repository_provider.g.dart';

/// 提供 AI 服务商与模型配置仓库。
@Riverpod(keepAlive: true)
Future<AiProviderRepository> aiProviderRepository(Ref ref) async {
  final isar = await ref.watch(aiProviderIsarProvider.future);
  return AiProviderRepository(isar);
}

/// 监听全部 AI 服务商配置。
@Riverpod(keepAlive: true)
Stream<List<AiProviderEntity>> aiProviders(Ref ref) async* {
  final repository = await ref.watch(aiProviderRepositoryProvider.future);
  yield* repository.watchProviders();
}

/// 监听全部本地模型配置。
@Riverpod(keepAlive: true)
Stream<List<AiModelEntity>> aiModels(Ref ref) async* {
  final repository = await ref.watch(aiProviderRepositoryProvider.future);
  yield* repository.watchModels();
}

/// 监听指定服务商下的模型配置。
@Riverpod(keepAlive: true)
Stream<List<AiModelEntity>> aiProviderModels(
  Ref ref,
  String providerId,
) async* {
  final repository = await ref.watch(aiProviderRepositoryProvider.future);
  yield* repository.watchModels(providerId: providerId);
}
