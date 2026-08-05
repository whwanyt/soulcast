import 'dart:io';

import 'package:flute_core/log/log.dart';
import 'package:path/path.dart' as p;
import 'package:soulcast/entities/speech_model/speech_model.dart';
import 'package:soulcast/shared/storage/app_directories.dart';

import '../api/speech_model_downloader.dart';
import 'speech_model_archive_extractor.dart';

/// 编排语音模型下载、解压、状态更新与默认模型维护。
class SpeechModelInstallService {
  SpeechModelInstallService({
    required this._repository,
    SpeechModelDownloader? downloader,
    SpeechModelArchiveExtractor? extractor,
  }) : _downloader = downloader ?? SpeechModelDownloader(),
       _extractor = extractor ?? const SpeechModelArchiveExtractor();

  final SpeechModelRepository _repository;
  final SpeechModelDownloader _downloader;
  final SpeechModelArchiveExtractor _extractor;

  final _progressById = <String, double>{};
  void Function()? onChanged;

  Map<String, double> get progressById => Map.unmodifiable(_progressById);

  Future<void> startListening() async {
    await _downloader.ensureReady();
    _downloader.listenUpdates(
      onStatus: _handleStatus,
      onProgress: _handleProgress,
    );
  }

  Future<SpeechModelEntity> addModel({
    required String downloadUrl,
    String? displayName,
    SpeechModelKind kind = SpeechModelKind.asr,
  }) async {
    final model = _repository.add(
      downloadUrl: downloadUrl,
      displayName: displayName,
      kind: kind,
    );
    Log.i(
      'Speech model added: id=${model.id}, kind=${kind.name}, url=$downloadUrl',
      tag: 'SpeechModel',
    );
    return model;
  }

  Future<void> startDownload(String modelId) async {
    final model = _repository.getById(modelId);
    if (model == null) {
      throw StateError('Model not found: $modelId');
    }
    final url = model.downloadUrl.trim();
    if (url.isEmpty) {
      throw StateError('Download URL is empty');
    }

    final filename = _filenameFromUrl(url);
    Log.i(
      'Speech model download start: modelId=$modelId, kind=${model.modelKind.name}',
      tag: 'SpeechModel',
    );
    _progressById[modelId] = 0;
    _repository.update(
      modelId,
      status: SpeechModelStatus.queued.name,
      downloadTaskId: modelId,
      bytesReceived: 0,
      bytesTotal: 0,
      errorMessage: '',
    );
    onChanged?.call();

    await _downloader.enqueue(modelId: modelId, url: url, filename: filename);
  }

  Future<void> cancelDownload(String modelId) async {
    final model = _repository.getById(modelId);
    if (model == null) {
      return;
    }
    final taskId = model.downloadTaskId.isEmpty
        ? modelId
        : model.downloadTaskId;
    Log.i('Speech model download cancel: modelId=$modelId', tag: 'SpeechModel');
    await _downloader.cancel(taskId);
    _progressById.remove(modelId);
    _repository.update(
      modelId,
      status: SpeechModelStatus.idle.name,
      errorMessage: '',
    );
    onChanged?.call();
  }

  Future<void> setDefault(String modelId) async {
    final updated = _repository.setDefault(modelId);
    if (updated == null) {
      throw StateError('Only ready models can be set as default');
    }
    Log.i(
      'Speech model set default: modelId=$modelId, kind=${updated.modelKind.name}',
      tag: 'SpeechModel',
    );
    onChanged?.call();
  }

  Future<void> deleteModel(String modelId) async {
    final model = _repository.getById(modelId);
    if (model == null) {
      return;
    }
    final taskId = model.downloadTaskId.isEmpty
        ? modelId
        : model.downloadTaskId;
    await _downloader.cancel(taskId);
    _progressById.remove(modelId);

    final dirs = await AppDirectories.resolve();
    final modelDir = Directory(p.join(dirs.models.path, modelId));
    if (modelDir.existsSync()) {
      await modelDir.delete(recursive: true);
    }

    _repository.delete(modelId);
    _repository.ensureDefaultOrPromote(kind: model.modelKind);
    Log.i(
      'Speech model deleted: modelId=$modelId, kind=${model.modelKind.name}',
      tag: 'SpeechModel',
    );
    onChanged?.call();
  }

  Future<void> clearAllModels() async {
    final models = _repository.getAll();
    Log.i('Speech model clear all: count=${models.length}', tag: 'SpeechModel');
    for (final model in models) {
      final taskId = model.downloadTaskId.isEmpty
          ? model.id
          : model.downloadTaskId;
      await _downloader.cancel(taskId);
    }
    _progressById.clear();
    final dirs = await AppDirectories.resolve();
    if (dirs.models.existsSync()) {
      await dirs.models.delete(recursive: true);
    }
    await dirs.models.create(recursive: true);
    _repository.deleteAll();
    onChanged?.call();
  }

  void _handleProgress(SpeechDownloadProgressEvent event) {
    final progress = event.progress;
    if (progress >= 0 && progress <= 1) {
      _progressById[event.modelId] = progress;
    }
    final expected = event.expectedFileSize;
    if (expected > 0) {
      final received = (expected * (progress.clamp(0, 1))).round();
      _repository.update(
        event.modelId,
        status: SpeechModelStatus.downloading.name,
        bytesTotal: expected,
        bytesReceived: received,
      );
    } else {
      _repository.update(
        event.modelId,
        status: SpeechModelStatus.downloading.name,
      );
    }
    onChanged?.call();
  }

  Future<void> _handleStatus(SpeechDownloadStatusEvent event) async {
    switch (event.phase) {
      case SpeechDownloadPhase.enqueued:
        _repository.update(
          event.modelId,
          status: SpeechModelStatus.queued.name,
        );
      case SpeechDownloadPhase.running:
        _repository.update(
          event.modelId,
          status: SpeechModelStatus.downloading.name,
        );
      case SpeechDownloadPhase.complete:
        await _installDownloaded(event.modelId, event.filePath);
      case SpeechDownloadPhase.canceled:
        _progressById.remove(event.modelId);
        _repository.update(
          event.modelId,
          status: SpeechModelStatus.idle.name,
          errorMessage: '',
        );
      case SpeechDownloadPhase.failed:
        _progressById.remove(event.modelId);
        _repository.update(
          event.modelId,
          status: SpeechModelStatus.failed.name,
          errorMessage: event.errorMessage.isEmpty
              ? 'download_failed'
              : event.errorMessage,
        );
      case SpeechDownloadPhase.paused:
      case SpeechDownloadPhase.waitingToRetry:
        break;
    }
    onChanged?.call();
  }

  Future<void> _installDownloaded(String modelId, String archivePath) async {
    _repository.update(modelId, status: SpeechModelStatus.extracting.name);
    onChanged?.call();
    Log.i(
      'Speech model extract start: modelId=$modelId, archive=$archivePath',
      tag: 'SpeechModel',
    );

    try {
      final dirs = await AppDirectories.resolve();
      final modelDir = Directory(p.join(dirs.models.path, modelId));
      final extractDir = Directory(p.join(modelDir.path, 'model'));
      final existing = _repository.getById(modelId);
      final kind = existing?.modelKind ?? SpeechModelKind.asr;
      await _extractor.extract(
        archiveFile: File(archivePath),
        targetDir: extractDir,
        kind: kind,
      );

      _progressById.remove(modelId);
      _repository.update(
        modelId,
        status: SpeechModelStatus.ready.name,
        localDir: extractDir.path,
        errorMessage: '',
        bytesReceived: _repository.getById(modelId)?.bytesTotal ?? 0,
      );
      _repository.ensureDefaultOrPromote(kind: kind);
      Log.i(
        'Speech model ready: modelId=$modelId, kind=${kind.name}, '
        'dir=${extractDir.path}',
        tag: 'SpeechModel',
      );
    } catch (error, stackTrace) {
      Log.e(
        'Speech model extract failed: modelId=$modelId, error=$error',
        tag: 'SpeechModel',
        error: error,
        stackTrace: stackTrace,
      );
      _progressById.remove(modelId);
      _repository.update(
        modelId,
        status: SpeechModelStatus.failed.name,
        errorMessage: error.toString(),
      );
    }
  }

  static String _filenameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final segment = uri?.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
    if (segment == null || segment.isEmpty) {
      return 'model.bin';
    }
    return segment;
  }
}
