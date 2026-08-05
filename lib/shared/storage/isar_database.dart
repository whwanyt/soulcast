import 'package:flute_core/log/logger.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/shared/storage/app_directories.dart';

part 'isar_database.g.dart';

const appIsarName = 'app';

List<IsarGeneratedSchema>? _appIsarSchemas;
Isar? _appIsar;
Future<Isar>? _appIsarOpening;

/// 在首次打开数据库前注册应用所需的全部 Isar schema。
void registerAppIsarSchemas(List<IsarGeneratedSchema> schemas) {
  if (_appIsar != null) {
    return;
  }
  _appIsarSchemas = schemas;
}

/// 提供应用级共享 Isar 实例。
@Riverpod(keepAlive: true)
Future<Isar> appIsar(Ref ref) async {
  return openAppIsar();
}

/// 打开或复用应用数据库。
///
/// 并发调用会等待同一个 opening future，避免重复打开同名数据库。
Future<Isar> openAppIsar() async {
  final existing = _appIsar;
  if (existing != null && existing.isOpen) {
    return existing;
  }

  final opening = _appIsarOpening;
  if (opening != null) {
    return opening;
  }

  final nextOpening = _openAppIsar();
  _appIsarOpening = nextOpening;
  try {
    return await nextOpening;
  } finally {
    _appIsarOpening = null;
  }
}

Future<Isar> _openAppIsar() async {
  try {
    final schemas = _appIsarSchemas;
    if (schemas == null || schemas.isEmpty) {
      throw StateError('App Isar schemas have not been registered.');
    }

    final databaseDirectory = (await AppDirectories.resolve()).isar;
    if (!databaseDirectory.existsSync()) {
      databaseDirectory.createSync(recursive: true);
    }

    final isar = Isar.open(
      schemas: schemas,
      directory: databaseDirectory.path,
      name: appIsarName,
    );
    _appIsar = isar;
    return isar;
  } catch (error, stackTrace) {
    Log.e(
      'App Isar open failed: $error',
      tag: 'START',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
