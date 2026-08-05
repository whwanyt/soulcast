import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/agent/llm.dart';

import '../service/generate_character_service.dart';

part 'generate_character_service.g.dart';

/// 提供角色卡 AI 生成服务。
@Riverpod(keepAlive: true)
GenerateCharacterService generateCharacterService(Ref ref) {
  return GenerateCharacterService(
    resolveRepository: () => ref.read(aiProviderRepositoryProvider.future),
    createClient: createLlmClient,
  );
}
