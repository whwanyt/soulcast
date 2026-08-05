import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/ai_provider_transfer_service.dart';

part 'ai_provider_transfer_service.g.dart';

/// 提供 AI 服务商 JSON 导入导出服务。
@Riverpod(keepAlive: true)
AiProviderTransferService aiProviderTransferService(Ref ref) {
  return const AiProviderTransferService();
}
