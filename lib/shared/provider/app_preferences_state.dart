part of 'app_preferences_provider.dart';

/// 全局运行态与需在启动时恢复的会话偏好快照。
class AppPreferencesState {
  const AppPreferencesState({
    required this.themeMode,
    required this.locale,
    required this.responseMode,
    this.customPrompts = const {},
    this.selectedConversationId,
    this.contextMessageLimitEnabled = false,
    this.contextMessageLimit = defaultContextMessageLimit,
    this.toolCallRoundsLimitEnabled = true,
    this.toolCallRoundsLimit = defaultToolCallRoundsLimit,
    this.temperatureEnabled = false,
    this.temperature = defaultTemperature,
    this.topP = defaultTopP,
    this.topK = defaultTopK,
    this.memoryWriteFrequencyEnabled = true,
    this.memoryWriteFrequency = defaultMemoryWriteFrequency,
    this.showToolMessages = true,
    this.showMemoryMessages = true,
    this.ttsSpeakerId = defaultTtsSpeakerId,
    this.ttsSpeed = defaultTtsSpeed,
    this.ttsReferenceAudioPath,
    this.user,
  });

  final AppThemeModePreference themeMode;
  final AppLocale locale;
  final ChatResponseModePreference responseMode;
  final Map<String, String> customPrompts;
  final String? selectedConversationId;
  final bool contextMessageLimitEnabled;
  final int contextMessageLimit;
  final bool toolCallRoundsLimitEnabled;
  final int toolCallRoundsLimit;
  final bool temperatureEnabled;
  final double temperature;
  final double topP;
  final int topK;
  final bool memoryWriteFrequencyEnabled;
  final int memoryWriteFrequency;
  final bool showToolMessages;
  final bool showMemoryMessages;
  final int ttsSpeakerId;
  final double ttsSpeed;
  final String? ttsReferenceAudioPath;

  /// 用户昵称；`null` 表示未设置。
  final String? user;

  /// 供提示词 `{{user}}` 使用的昵称；未设置时为空串。
  String get promptUser => user?.trim() ?? '';

  /// 开启时返回限制条数，关闭时返回 `null`（无限制）。
  int? get effectiveContextMessageLimit =>
      contextMessageLimitEnabled ? contextMessageLimit : null;

  /// 开启时返回工具轮次上限，关闭时返回 `null`（无限制）。
  int? get effectiveToolCallRoundsLimit =>
      toolCallRoundsLimitEnabled ? toolCallRoundsLimit : null;

  /// 开启时返回 temperature，关闭时返回 `null`（不传参）。
  double? get effectiveTemperature => temperatureEnabled ? temperature : null;

  /// `0` 表示不传 top_p。
  double? get effectiveTopP => topP > 0 ? topP : null;

  /// `0` 表示不传 top_k。
  int? get effectiveTopK => topK > 0 ? topK : null;

  /// 开启时返回写入间隔，关闭时返回 `null`（不生成记忆）。
  int? get effectiveMemoryWriteFrequency =>
      memoryWriteFrequencyEnabled ? memoryWriteFrequency : null;

  String? customPrompt(PromptId id) => customPromptOf(customPrompts, id);

  AppPreferencesState copyWith({
    AppThemeModePreference? themeMode,
    AppLocale? locale,
    ChatResponseModePreference? responseMode,
    Map<String, String>? customPrompts,
    Object? selectedConversationId = _unset,
    bool? contextMessageLimitEnabled,
    int? contextMessageLimit,
    bool? toolCallRoundsLimitEnabled,
    int? toolCallRoundsLimit,
    bool? temperatureEnabled,
    double? temperature,
    double? topP,
    int? topK,
    bool? memoryWriteFrequencyEnabled,
    int? memoryWriteFrequency,
    bool? showToolMessages,
    bool? showMemoryMessages,
    int? ttsSpeakerId,
    double? ttsSpeed,
    Object? ttsReferenceAudioPath = _unset,
    Object? user = _unset,
  }) {
    return AppPreferencesState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      responseMode: responseMode ?? this.responseMode,
      customPrompts: customPrompts ?? this.customPrompts,
      selectedConversationId: selectedConversationId == _unset
          ? this.selectedConversationId
          : selectedConversationId as String?,
      contextMessageLimitEnabled:
          contextMessageLimitEnabled ?? this.contextMessageLimitEnabled,
      contextMessageLimit: contextMessageLimit ?? this.contextMessageLimit,
      toolCallRoundsLimitEnabled:
          toolCallRoundsLimitEnabled ?? this.toolCallRoundsLimitEnabled,
      toolCallRoundsLimit: toolCallRoundsLimit ?? this.toolCallRoundsLimit,
      temperatureEnabled: temperatureEnabled ?? this.temperatureEnabled,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      memoryWriteFrequencyEnabled:
          memoryWriteFrequencyEnabled ?? this.memoryWriteFrequencyEnabled,
      memoryWriteFrequency: memoryWriteFrequency ?? this.memoryWriteFrequency,
      showToolMessages: showToolMessages ?? this.showToolMessages,
      showMemoryMessages: showMemoryMessages ?? this.showMemoryMessages,
      ttsSpeakerId: ttsSpeakerId ?? this.ttsSpeakerId,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ttsReferenceAudioPath: ttsReferenceAudioPath == _unset
          ? this.ttsReferenceAudioPath
          : ttsReferenceAudioPath as String?,
      user: user == _unset ? this.user : user as String?,
    );
  }
}
