import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/character_transfer_service.dart';

part 'character_transfer_service.g.dart';

/// 提供角色卡文件导入服务。
@Riverpod(keepAlive: true)
CharacterTransferService characterTransferService(Ref ref) {
  return const CharacterTransferService();
}
