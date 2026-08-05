import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';

import '../service/speech_model_install_service.dart';

part 'manage_speech_model.g.dart';

/// 暴露各语音模型当前下载进度。
@Riverpod(keepAlive: true)
class SpeechModelDownloadProgress extends _$SpeechModelDownloadProgress {
  @override
  Map<String, double> build() => const {};

  void replaceAll(Map<String, double> next) {
    state = Map.unmodifiable(next);
  }
}

/// 管理语音模型安装服务的生命周期并转发用户动作。
@Riverpod(keepAlive: true)
class ManageSpeechModel extends _$ManageSpeechModel {
  SpeechModelInstallService? _service;

  @override
  Future<SpeechModelInstallService> build() async {
    final repository = await ref.watch(speechModelRepositoryProvider.future);
    final service = SpeechModelInstallService(repository: repository);
    service.onChanged = () {
      if (!ref.mounted) {
        return;
      }
      ref
          .read(speechModelDownloadProgressProvider.notifier)
          .replaceAll(service.progressById);
    };
    await service.startListening();
    _service = service;
    ref.onDispose(() {
      service.onChanged = null;
    });
    return service;
  }

  SpeechModelInstallService get _requireService {
    final service = _service ?? state.asData?.value;
    if (service == null) {
      throw StateError('Speech model manager is not ready');
    }
    return service;
  }

  Future<SpeechModelEntity> addModel({
    required String downloadUrl,
    String? displayName,
    SpeechModelKind kind = SpeechModelKind.asr,
  }) {
    return _requireService.addModel(
      downloadUrl: downloadUrl,
      displayName: displayName,
      kind: kind,
    );
  }

  Future<void> startDownload(String modelId) {
    return _requireService.startDownload(modelId);
  }

  Future<void> cancelDownload(String modelId) {
    return _requireService.cancelDownload(modelId);
  }

  Future<void> setDefault(String modelId) {
    return _requireService.setDefault(modelId);
  }

  Future<void> deleteModel(String modelId) {
    return _requireService.deleteModel(modelId);
  }
}
