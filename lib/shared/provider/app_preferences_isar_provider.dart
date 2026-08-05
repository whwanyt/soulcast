import 'package:isar_plus/isar_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/shared/storage/isar_database.dart';

part 'app_preferences_isar_provider.g.dart';

/// 提供已注册应用偏好 schema 的共享 Isar 实例。
@Riverpod(keepAlive: true)
Future<Isar> appPreferencesIsar(Ref ref) async {
  return ref.watch(appIsarProvider.future);
}
