import 'package:flute_core/log/log.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/agent/llm.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/storage/image_file_store.dart';

import '../model/agent_tool_config.dart';
import '../model/agent_tool_ids.dart';
import 'agent_tool.dart';

/// 解析当前配置的图片模型。
typedef ResolveGenerateImageModel = Future<AiModelEntity?> Function();

/// 根据模型 id 解析图片请求客户端配置。
typedef ResolveGenerateImageSettings =
    Future<ChatSettings?> Function(String modelId);

/// 创建图片生成客户端。
typedef CreateGenerateImageClient = LlmClient Function(ChatSettings settings);

/// 将图片 base64 内容持久化为可展示 URI。
typedef PersistGeneratedImageB64 = Future<Uri> Function(String b64Json);

/// 将远端图片 URL 持久化为可展示 URI。
typedef PersistGeneratedImageUrl = Future<Uri> Function(String url);

/// 使用已配置图片模型生成图片的 Agent 工具。
///
/// url / b64_json 均先落盘，再返回本地 `file://` 展示地址。
class GenerateImageTool extends AgentTool {
  const GenerateImageTool({
    required this.resolveImageModel,
    required this.resolveClientSettings,
    this.createClient = createLlmClient,
    this.persistB64Json,
    this.persistUrl,
    this.imageStore = const ImageFileStore(fileNamePrefix: 'gen'),
  });

  static const toolName = AgentToolIds.generateImage;
  static const imageModelIdParam = AgentToolIds.imageModelId;

  final ResolveGenerateImageModel resolveImageModel;
  final ResolveGenerateImageSettings resolveClientSettings;
  final CreateGenerateImageClient createClient;
  final PersistGeneratedImageB64? persistB64Json;
  final PersistGeneratedImageUrl? persistUrl;
  final ImageFileStore imageStore;

  @override
  String get name => toolName;

  @override
  String get displayName => t.agent.generateImage.toolName;

  @override
  String get description => t.agent.generateImage.toolDescription;

  @override
  List<AgentToolSettingField> get settingFields => [
    AgentToolSettingField(
      key: imageModelIdParam,
      label: t.agent.generateImage.imageModelLabel,
      hintText: t.agent.generateImage.imageModelHint,
      type: AgentToolSettingFieldType.modelByOutputFormat,
      requiredOutputFormat: AiModelFormatTags.image,
    ),
  ];

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{
      'prompt': <String, dynamic>{
        'type': 'string',
        'description': 'Text description of the image to generate.',
      },
      'size': <String, dynamic>{
        'type': 'string',
        'description':
            'Optional image size such as 1024x1024, 1792x1024, or 1024x1792. '
            'Omit if unsure.',
      },
    },
    'required': <String>['prompt'],
    'additionalProperties': false,
  };

  @override
  bool get strict => true;

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    final imageModel = await resolveImageModel();
    if (imageModel == null) {
      return {
        'status': 'missing_image_model',
        'message': t.agent.generateImage.missingImageModelResult,
      };
    }
    if (!imageModel.isEnabled ||
        !imageModel.hasOutputFormat(AiModelFormatTags.image)) {
      return {
        'status': 'invalid_image_model',
        'message': t.agent.generateImage.invalidImageModelResult,
      };
    }

    final prompt = _readString(arguments['prompt']);
    if (prompt == null || prompt.isEmpty) {
      return {
        'status': 'invalid_arguments',
        'message': t.agent.generateImage.invalidArgumentsResult,
      };
    }

    final size = _readString(arguments['size']);
    final settings = await resolveClientSettings(imageModel.id);
    if (settings == null) {
      return {
        'status': 'missing_provider',
        'message': t.agent.generateImage.missingProviderResult,
      };
    }
    if (!settings.hasApiKey) {
      return {
        'status': 'missing_api_key',
        'message': t.agent.generateImage.missingApiKeyResult,
      };
    }

    LlmClient? client;
    try {
      client = createClient(settings);
      final generation = await client.createImage(
        LlmImageRequest(prompt: prompt, model: imageModel.model, size: size),
      );
      final displayUrl = await _resolveDisplayUrl(generation);
      final markdown = '![generated image]($displayUrl)';
      return {
        'status': 'success',
        'url': displayUrl,
        if (generation.revisedPrompt != null)
          'revisedPrompt': generation.revisedPrompt,
        'markdown': markdown,
      };
    } on LlmException catch (error, stackTrace) {
      Log.e(
        'GenerateImageTool failed: ${error.message}',
        tag: 'Tool',
        error: error,
        stackTrace: stackTrace,
      );
      return {'status': 'request_failed', 'message': error.message};
    } catch (error, stackTrace) {
      Log.e(
        'GenerateImageTool failed unexpectedly: $error',
        tag: 'Tool',
        error: error,
        stackTrace: stackTrace,
      );
      return {
        'status': 'request_failed',
        'message': t.agent.generateImage.requestFailedResult,
        'error': error.toString(),
      };
    } finally {
      client?.close();
    }
  }

  Future<String> _resolveDisplayUrl(LlmImageGeneration generation) async {
    if (generation.hasUrl) {
      final persist = persistUrl ?? imageStore.saveFromUrl;
      final uri = await persist(generation.url!);
      return uri.toString();
    }
    if (!generation.hasB64Json) {
      throw const LlmException(
        'Image generation returned neither url nor b64_json',
      );
    }
    final persist = persistB64Json ?? imageStore.saveB64Json;
    final uri = await persist(generation.b64Json!);
    return uri.toString();
  }

  static String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
