import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repository/speech_model_repository.dart';
import '../speech_model_entity.dart';
import '../speech_model_kind.dart';
import 'isar_provider.dart';

part 'speech_model_repository_provider.g.dart';

/// 提供本地语音模型仓库。
@Riverpod(keepAlive: true)
Future<SpeechModelRepository> speechModelRepository(Ref ref) async {
  final isar = await ref.watch(speechModelIsarProvider.future);
  return SpeechModelRepository(isar);
}

/// 监听全部本地语音模型。
@Riverpod(keepAlive: true)
Stream<List<SpeechModelEntity>> speechModels(Ref ref) async* {
  final repository = await ref.watch(speechModelRepositoryProvider.future);
  yield* repository.watchAll();
}

/// 返回当前默认 ASR 模型。
@Riverpod(keepAlive: true)
SpeechModelEntity? defaultSpeechModel(Ref ref) {
  return _defaultOfKind(ref, SpeechModelKind.asr);
}

/// 返回当前默认 TTS 模型。
@Riverpod(keepAlive: true)
SpeechModelEntity? defaultTtsSpeechModel(Ref ref) {
  return _defaultOfKind(ref, SpeechModelKind.tts);
}

SpeechModelEntity? _defaultOfKind(Ref ref, SpeechModelKind kind) {
  final models = ref
      .watch(speechModelsProvider)
      .maybeWhen(data: (value) => value, orElse: () => null);
  if (models == null) {
    return null;
  }
  for (final model in models) {
    if (model.isDefault && model.modelKind == kind) {
      return model;
    }
  }
  return null;
}
