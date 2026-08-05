import 'package:isar_plus/isar_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/shared/storage/isar_database.dart';

part 'isar_provider.g.dart';

/// 角色实体使用的应用级共享 Isar 实例。
@Riverpod(keepAlive: true)
Future<Isar> characterIsar(Ref ref) async {
  return ref.watch(appIsarProvider.future);
}
