import 'package:flute_core/log/log.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/agent/llm.dart';
import 'package:soulcast/shared/storage/image_file_store.dart';

import '../model/generated_character_draft.dart';
import 'generate_character_prompt_builder.dart';

/// 延迟获取 AI 供应商仓库。
typedef AiProviderRepositoryGetter = Future<AiProviderRepository> Function();

/// 创建 LLM 客户端。
typedef CreateGenerateCharacterClient =
    LlmClient Function(ChatSettings settings);

/// 编排角色卡文本生成与头像生成。
class GenerateCharacterService {
  const GenerateCharacterService({
    required this.resolveRepository,
    this.createClient = createLlmClient,
    this.avatarStore = const ImageFileStore(fileNamePrefix: 'avatar'),
  });

  final AiProviderRepositoryGetter resolveRepository;
  final CreateGenerateCharacterClient createClient;
  final ImageFileStore avatarStore;

  /// 根据创意生成角色卡文本草稿；不生成头像。
  Future<GeneratedCharacterDraft?> generate({
    required String idea,
    required String textModelId,
    required String systemTemplate,
    required String userTemplate,
    String? systemFallbackTemplate,
    String? userFallbackTemplate,
  }) async {
    final trimmedIdea = idea.trim();
    if (trimmedIdea.isEmpty) {
      return null;
    }

    final repository = await resolveRepository();
    final settings = resolveProviderClientSettings(
      repository: repository,
      modelId: textModelId,
    );
    if (settings == null || !settings.hasApiKey) {
      Log.w(
        'Generate character skipped: missing provider settings or api key',
        tag: 'Character',
      );
      return null;
    }

    LlmClient? client;
    try {
      client = createClient(settings);
      final systemPrompt = await buildGenerateCharacterSystemPrompt(
        template: systemTemplate,
        fallbackTemplate: systemFallbackTemplate,
      );
      final userPrompt = await buildGenerateCharacterUserPrompt(
        trimmedIdea,
        template: userTemplate,
        fallbackTemplate: userFallbackTemplate,
      );
      final response = await client.createChatCompletion(
        LlmChatRequest(
          model: settings.model,
          messages: [
            LlmMessage.system(systemPrompt),
            LlmMessage.user(userPrompt),
          ],
          temperature: 0.8,
          maxTokens: 2400,
          responseFormat: LlmResponseFormat.jsonObject,
        ),
      );

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        Log.w('Generate character skipped: empty response', tag: 'Character');
        return null;
      }

      return parseGeneratedCharacterDraft(text);
    } catch (error, stackTrace) {
      Log.e(
        'Generate character failed: $error',
        tag: 'Character',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      client?.close();
    }
  }

  /// 使用指定图像模型与提示词生成头像。
  ///
  /// [size] 为 Images API 的尺寸字符串（如 `1024x1024`）；`null` 表示服务端默认。
  Future<String?> generateAvatar({
    required String prompt,
    required String imageModelId,
    required String wrapTemplate,
    String? wrapFallbackTemplate,
    String? size,
  }) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return null;
    }

    final repository = await resolveRepository();
    final model = repository.getModel(imageModelId);
    if (model == null ||
        !model.isEnabled ||
        !model.hasOutputFormat(AiModelFormatTags.image)) {
      Log.w(
        'Generate character avatar skipped: invalid image model',
        tag: 'Character',
      );
      return null;
    }

    final settings = resolveProviderClientSettings(
      repository: repository,
      modelId: imageModelId,
    );
    if (settings == null || !settings.hasApiKey) {
      Log.w(
        'Generate character avatar skipped: missing provider settings or api key',
        tag: 'Character',
      );
      return null;
    }

    LlmClient? client;
    try {
      client = createClient(settings);
      final imagePrompt = await buildCharacterAvatarImagePrompt(
        trimmedPrompt,
        template: wrapTemplate,
        fallbackTemplate: wrapFallbackTemplate,
      );
      final generation = await client.createImage(
        LlmImageRequest(prompt: imagePrompt, model: model.model, size: size),
      );
      if (generation.hasUrl) {
        final uri = await avatarStore.saveFromUrl(generation.url!.trim());
        return uri.toString();
      }
      if (!generation.hasB64Json) {
        return null;
      }
      final uri = await avatarStore.saveB64Json(generation.b64Json!);
      return uri.toString();
    } catch (error, stackTrace) {
      Log.e(
        'Generate character avatar failed: $error',
        tag: 'Character',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      client?.close();
    }
  }
}
