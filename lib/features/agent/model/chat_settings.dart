import 'package:soulcast/entities/ai_provider/ai_provider.dart';

class _Unset {
  const _Unset();
}

const _unset = _Unset();

/// 单次聊天请求所需的模型、服务商与生成参数快照。
class ChatSettings {
  const ChatSettings({
    required this.apiKey,
    required this.baseUrl,
    this.apiPath = '',
    this.apiMode = AiProviderApiMode.chatCompletions,
    this.backgroundEnabled = false,
    required this.timeout,
    required this.connectTimeout,
    required this.maxRetries,
    required this.model,
    this.modelId,
    this.modelName,
    this.providerId,
    this.providerName,
    this.organization,
    this.project,
    this.systemPrompt,
    this.cardSystemPrompt,
    this.loreBeforeChar,
    this.characterPrompt,
    this.loreAfterChar,
    this.postHistoryInstructions,
    this.memoryInjectTemplate,
    this.memoryInjectFallbackTemplate,
    this.maxTokens,
    this.maxCompletionTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.maxContextMessages,
    this.maxToolRounds,
  });

  final String apiKey;
  final String baseUrl;
  final String apiPath;
  final AiProviderApiMode apiMode;

  /// Responses 下是否启用 background 取回；Completions 忽略。
  final bool backgroundEnabled;
  final Duration timeout;
  final Duration connectTimeout;
  final int maxRetries;
  final String? organization;
  final String? project;
  final String model;
  final String? modelId;
  final String? modelName;
  final String? providerId;
  final String? providerName;
  final String? systemPrompt;

  /// 角色卡级 system_prompt；仅角色会话使用。
  final String? cardSystemPrompt;

  /// 世界书 before_char 注入文本。
  final String? loreBeforeChar;

  /// 角色会话的角色卡系统提示词；`null` 表示普通会话。
  final String? characterPrompt;

  /// 世界书 after_char 注入文本。
  final String? loreAfterChar;

  /// 角色卡 post_history_instructions；插入历史消息之后。
  final String? postHistoryInstructions;

  /// 长期记忆注入模板；`null` 时不渲染记忆 system。
  final String? memoryInjectTemplate;

  /// 记忆注入模板渲染失败时的回退默认模板。
  final String? memoryInjectFallbackTemplate;
  final int? maxTokens;
  final int? maxCompletionTokens;
  final double? temperature;
  final double? topP;
  final int? topK;

  /// 发送给模型的历史消息上限；`null` 表示不限制。
  final int? maxContextMessages;

  /// 单次回复内工具调用轮次上限；`null` 表示不限制。
  final int? maxToolRounds;

  /// 是否为角色会话（携带角色卡）。
  bool get isRolePlay {
    final prompt = characterPrompt?.trim();
    return prompt != null && prompt.isNotEmpty;
  }

  bool get hasApiKey {
    final trimmedApiKey = apiKey.trim();
    return trimmedApiKey.isNotEmpty && trimmedApiKey != 'YOUR_API_KEY';
  }

  /// Responses + 开启 background 时，才可跨进程取回。
  bool get usesBackgroundResponse =>
      apiMode == AiProviderApiMode.responses && backgroundEnabled;

  /// 合并服务根地址与可选 API 路径前缀后的请求基址。
  String get apiBaseUrl => _joinBaseUrlAndPath(baseUrl, apiPath);

  ChatSettings copyWith({
    String? apiKey,
    String? baseUrl,
    String? apiPath,
    AiProviderApiMode? apiMode,
    bool? backgroundEnabled,
    Duration? timeout,
    Duration? connectTimeout,
    int? maxRetries,
    Object? organization = _unset,
    Object? project = _unset,
    String? model,
    Object? modelId = _unset,
    Object? modelName = _unset,
    Object? providerId = _unset,
    Object? providerName = _unset,
    Object? systemPrompt = _unset,
    Object? cardSystemPrompt = _unset,
    Object? loreBeforeChar = _unset,
    Object? characterPrompt = _unset,
    Object? loreAfterChar = _unset,
    Object? postHistoryInstructions = _unset,
    Object? memoryInjectTemplate = _unset,
    Object? memoryInjectFallbackTemplate = _unset,
    Object? maxTokens = _unset,
    Object? maxCompletionTokens = _unset,
    Object? temperature = _unset,
    Object? topP = _unset,
    Object? topK = _unset,
    Object? maxContextMessages = _unset,
    Object? maxToolRounds = _unset,
  }) {
    return ChatSettings(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      apiPath: apiPath ?? this.apiPath,
      apiMode: apiMode ?? this.apiMode,
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      timeout: timeout ?? this.timeout,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      maxRetries: maxRetries ?? this.maxRetries,
      organization: organization == _unset
          ? this.organization
          : organization as String?,
      project: project == _unset ? this.project : project as String?,
      model: model ?? this.model,
      modelId: modelId == _unset ? this.modelId : modelId as String?,
      modelName: modelName == _unset ? this.modelName : modelName as String?,
      providerId: providerId == _unset
          ? this.providerId
          : providerId as String?,
      providerName: providerName == _unset
          ? this.providerName
          : providerName as String?,
      systemPrompt: systemPrompt == _unset
          ? this.systemPrompt
          : systemPrompt as String?,
      cardSystemPrompt: cardSystemPrompt == _unset
          ? this.cardSystemPrompt
          : cardSystemPrompt as String?,
      loreBeforeChar: loreBeforeChar == _unset
          ? this.loreBeforeChar
          : loreBeforeChar as String?,
      characterPrompt: characterPrompt == _unset
          ? this.characterPrompt
          : characterPrompt as String?,
      loreAfterChar: loreAfterChar == _unset
          ? this.loreAfterChar
          : loreAfterChar as String?,
      postHistoryInstructions: postHistoryInstructions == _unset
          ? this.postHistoryInstructions
          : postHistoryInstructions as String?,
      memoryInjectTemplate: memoryInjectTemplate == _unset
          ? this.memoryInjectTemplate
          : memoryInjectTemplate as String?,
      memoryInjectFallbackTemplate: memoryInjectFallbackTemplate == _unset
          ? this.memoryInjectFallbackTemplate
          : memoryInjectFallbackTemplate as String?,
      maxTokens: maxTokens == _unset ? this.maxTokens : maxTokens as int?,
      maxCompletionTokens: maxCompletionTokens == _unset
          ? this.maxCompletionTokens
          : maxCompletionTokens as int?,
      temperature: temperature == _unset
          ? this.temperature
          : temperature as double?,
      topP: topP == _unset ? this.topP : topP as double?,
      topK: topK == _unset ? this.topK : topK as int?,
      maxContextMessages: maxContextMessages == _unset
          ? this.maxContextMessages
          : maxContextMessages as int?,
      maxToolRounds: maxToolRounds == _unset
          ? this.maxToolRounds
          : maxToolRounds as int?,
    );
  }
}

String _joinBaseUrlAndPath(String baseUrl, String apiPath) {
  final normalizedBaseUrl = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  final normalizedApiPath = apiPath.trim();
  if (normalizedApiPath.isEmpty || normalizedApiPath == '/') {
    return normalizedBaseUrl;
  }
  final path = normalizedApiPath.startsWith('/')
      ? normalizedApiPath
      : '/$normalizedApiPath';
  return '$normalizedBaseUrl${path.replaceFirst(RegExp(r'/+$'), '')}';
}
