import 'package:background_downloader/background_downloader.dart';
import 'package:flute_core/log/log.dart';
import 'package:soulcast/shared/storage/app_directories.dart';

/// 后台下载器上报的模型下载阶段。
enum SpeechDownloadPhase {
  enqueued,
  running,
  complete,
  canceled,
  failed,
  paused,
  waitingToRetry,
}

/// 模型后台下载状态事件。
class SpeechDownloadStatusEvent {
  const SpeechDownloadStatusEvent({
    required this.modelId,
    required this.phase,
    required this.filePath,
    this.errorMessage = '',
  });

  final String modelId;
  final SpeechDownloadPhase phase;
  final String filePath;
  final String errorMessage;
}

/// 模型后台下载进度事件。
class SpeechDownloadProgressEvent {
  const SpeechDownloadProgressEvent({
    required this.modelId,
    required this.progress,
    required this.expectedFileSize,
  });

  final String modelId;
  final double progress;
  final int expectedFileSize;
}

/// `background_downloader` 适配：仅本 feature 的 api 层可依赖该 SDK。
class SpeechModelDownloader {
  SpeechModelDownloader({FileDownloader? downloader})
    : _downloader = downloader ?? FileDownloader();

  final FileDownloader _downloader;
  var _listening = false;

  Future<void> ensureReady() => _downloader.ready;

  void listenUpdates({
    required void Function(SpeechDownloadStatusEvent event) onStatus,
    required void Function(SpeechDownloadProgressEvent event) onProgress,
  }) {
    if (_listening) {
      return;
    }
    _listening = true;
    Log.i('Speech model download listener ready', tag: 'SpeechModel');
    _downloader.registerCallbacks(
      group: speechModelDownloadGroup,
      taskStatusCallback: (update) async {
        final modelId = update.task.metaData;
        if (modelId.isEmpty) {
          return;
        }
        final phase = switch (update.status) {
          TaskStatus.enqueued => SpeechDownloadPhase.enqueued,
          TaskStatus.running => SpeechDownloadPhase.running,
          TaskStatus.complete => SpeechDownloadPhase.complete,
          TaskStatus.canceled => SpeechDownloadPhase.canceled,
          TaskStatus.failed ||
          TaskStatus.notFound => SpeechDownloadPhase.failed,
          TaskStatus.paused => SpeechDownloadPhase.paused,
          TaskStatus.waitingToRetry => SpeechDownloadPhase.waitingToRetry,
        };
        var filePath = '';
        if (update.status == TaskStatus.complete &&
            update.task is DownloadTask) {
          filePath = await (update.task as DownloadTask).filePath();
        }
        if (phase == SpeechDownloadPhase.failed) {
          Log.e(
            'Speech model download failed: modelId=$modelId, '
            'error=${update.exception}',
            tag: 'SpeechModel',
          );
        } else {
          Log.d(
            'Speech model download status: modelId=$modelId, phase=$phase',
            tag: 'SpeechModel',
          );
        }
        onStatus(
          SpeechDownloadStatusEvent(
            modelId: modelId,
            phase: phase,
            filePath: filePath,
            errorMessage: update.exception?.toString() ?? '',
          ),
        );
      },
      taskProgressCallback: (update) {
        final modelId = update.task.metaData;
        if (modelId.isEmpty) {
          return;
        }
        onProgress(
          SpeechDownloadProgressEvent(
            modelId: modelId,
            progress: update.progress,
            expectedFileSize: update.expectedFileSize,
          ),
        );
      },
    );
  }

  Future<void> enqueue({
    required String modelId,
    required String url,
    required String filename,
  }) async {
    await ensureReady();
    final task = DownloadTask(
      taskId: modelId,
      url: url,
      filename: filename,
      directory: '${AppDirectories.modelsRelativePath}/$modelId',
      baseDirectory: BaseDirectory.applicationSupport,
      group: speechModelDownloadGroup,
      updates: Updates.statusAndProgress,
      retries: 2,
      allowPause: true,
      metaData: modelId,
      displayName: filename,
    );
    Log.d(
      'Speech model download enqueue: modelId=$modelId, '
      'filename=$filename, url=$url',
      tag: 'SpeechModel',
    );
    final enqueued = await _downloader.enqueue(task);
    if (!enqueued) {
      Log.e(
        'Speech model download enqueue rejected: modelId=$modelId',
        tag: 'SpeechModel',
      );
      throw StateError('Failed to enqueue download for $modelId');
    }
  }

  Future<bool> cancel(String taskId) {
    Log.d('Speech model download cancel: taskId=$taskId', tag: 'SpeechModel');
    return _downloader.cancelTaskWithId(taskId);
  }
}

const speechModelDownloadGroup = 'speech_models';
