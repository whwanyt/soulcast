import 'package:isar_plus/isar_plus.dart';

import '../speech_model_entity.dart';
import '../speech_model_kind.dart';
import '../speech_model_status.dart';

/// 本地语音模型元数据的 Isar 仓库。
///
/// 仓库负责维持每种模型类型最多一个默认模型的不变量。
class SpeechModelRepository {
  const SpeechModelRepository(this._isar);

  final Isar _isar;

  List<SpeechModelEntity> getAll() {
    return _sort(
      _isar.collection<String, SpeechModelEntity>().where().findAll(),
    );
  }

  Stream<List<SpeechModelEntity>> watchAll() {
    return _isar
        .collection<String, SpeechModelEntity>()
        .where()
        .watch(fireImmediately: true)
        .map(_sort);
  }

  SpeechModelEntity? getById(String id) {
    return _isar.collection<String, SpeechModelEntity>().get(id);
  }

  SpeechModelEntity? getDefault({SpeechModelKind kind = SpeechModelKind.asr}) {
    for (final model in getAll()) {
      if (model.isDefault && model.modelKind == kind) {
        return model;
      }
    }
    return null;
  }

  SpeechModelEntity add({
    required String downloadUrl,
    String? displayName,
    SpeechModelKind kind = SpeechModelKind.asr,
  }) {
    final now = DateTime.now();
    final id = createModelId();
    final url = downloadUrl.trim();
    final name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : _displayNameFromUrl(url);
    final entity = SpeechModelEntity(
      id: id,
      displayName: name,
      downloadUrl: url,
      kind: kind.name,
      status: SpeechModelStatus.idle.name,
      localDir: '',
      downloadTaskId: '',
      bytesTotal: 0,
      bytesReceived: 0,
      errorMessage: '',
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );
    _isar.write((isar) {
      isar.collection<String, SpeechModelEntity>().put(entity);
    });
    return entity;
  }

  SpeechModelEntity? update(
    String id, {
    String? displayName,
    String? status,
    String? localDir,
    String? downloadTaskId,
    int? bytesTotal,
    int? bytesReceived,
    String? errorMessage,
    bool? isDefault,
  }) {
    late SpeechModelEntity? entity;
    _isar.write((isar) {
      final collection = isar.collection<String, SpeechModelEntity>();
      final existing = collection.get(id);
      if (existing == null) {
        entity = null;
        return;
      }
      entity = existing.copyWith(
        displayName: displayName,
        status: status,
        localDir: localDir,
        downloadTaskId: downloadTaskId,
        bytesTotal: bytesTotal,
        bytesReceived: bytesReceived,
        errorMessage: errorMessage,
        isDefault: isDefault,
        updatedAt: DateTime.now(),
      );
      collection.put(entity!);
    });
    return entity;
  }

  /// 将指定模型设为默认；同 kind 其它模型取消默认。仅允许 ready。
  SpeechModelEntity? setDefault(String id) {
    late SpeechModelEntity? result;
    _isar.write((isar) {
      final collection = isar.collection<String, SpeechModelEntity>();
      final target = collection.get(id);
      if (target == null ||
          SpeechModelStatus.parse(target.status) != SpeechModelStatus.ready) {
        result = null;
        return;
      }

      final now = DateTime.now();
      for (final item in collection.where().findAll()) {
        if (item.modelKind != target.modelKind) {
          continue;
        }
        final nextDefault = item.id == id;
        if (item.isDefault == nextDefault && item.id != id) {
          continue;
        }
        final updated = item.copyWith(
          isDefault: nextDefault,
          updatedAt: now,
          errorMessage: nextDefault ? '' : item.errorMessage,
        );
        collection.put(updated);
        if (nextDefault) {
          result = updated;
        }
      }
    });
    return result;
  }

  /// 首个 ready 且尚无默认时自动设默认；删除默认后补位。
  SpeechModelEntity? ensureDefaultOrPromote({
    SpeechModelKind kind = SpeechModelKind.asr,
  }) {
    final models = getAll().where((item) => item.modelKind == kind).toList();
    final currentDefault = models.where((item) => item.isDefault).firstOrNull;
    if (currentDefault != null &&
        currentDefault.modelStatus == SpeechModelStatus.ready) {
      return currentDefault;
    }

    final ready = models
        .where((item) => item.modelStatus == SpeechModelStatus.ready)
        .toList();
    if (ready.isEmpty) {
      if (currentDefault != null) {
        update(currentDefault.id, isDefault: false);
      }
      return null;
    }

    return setDefault(ready.first.id);
  }

  bool delete(String id) {
    var deleted = false;
    _isar.write((isar) {
      deleted = isar.collection<String, SpeechModelEntity>().delete(id);
    });
    return deleted;
  }

  void deleteAll() {
    _isar.write((isar) {
      final collection = isar.collection<String, SpeechModelEntity>();
      for (final item in collection.where().findAll()) {
        collection.delete(item.id);
      }
    });
  }

  String createModelId() {
    return 'speech_${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _displayNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final segment = uri?.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
    if (segment == null || segment.isEmpty) {
      return url;
    }
    return segment
        .replaceAll(
          RegExp(r'\.(tar\.bz2|tar\.gz|tgz|zip)$', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'[_\-]+'), ' ');
  }

  static List<SpeechModelEntity> _sort(List<SpeechModelEntity> items) {
    final sorted = [...items]
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        // 用 createdAt 保持列表稳定；进度刷新会改 updatedAt，不能参与排序。
        final byCreated = b.createdAt.compareTo(a.createdAt);
        if (byCreated != 0) {
          return byCreated;
        }
        return a.id.compareTo(b.id);
      });
    return sorted;
  }
}
