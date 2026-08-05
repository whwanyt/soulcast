import 'package:isar_plus/isar_plus.dart';

part 'app_preferences_entity.g.dart';

/// 应用全局偏好的 Isar 单例记录。
@collection
class AppPreferencesEntity {
  AppPreferencesEntity({
    required this.id,
    required this.themeModeName,
    required this.localeName,
    required this.responseModeName,
    this.customPromptsJson,
    this.selectedConversationId,
    this.contextMessageLimitEnabled,
    this.contextMessageLimit = defaultContextMessageLimit,
    this.toolCallRoundsLimitEnabled,
    this.toolCallRoundsLimit = defaultToolCallRoundsLimit,
    this.temperatureEnabled,
    this.temperature = defaultTemperature,
    this.topP = defaultTopP,
    this.topK = defaultTopK,
    this.memoryWriteFrequencyEnabled,
    this.memoryWriteFrequency = defaultMemoryWriteFrequency,
    this.showToolMessages,
    this.showMemoryMessages,
    this.ttsSpeakerId = defaultTtsSpeakerId,
    this.ttsSpeed = defaultTtsSpeed,
    this.ttsReferenceAudioPath,
    this.user,
    required this.updatedAt,
  });

  final String id;

  String themeModeName;
  String localeName;
  String responseModeName;

  /// 自定义提示词 Map 的 JSON：`{ promptId: template }`。
  String? customPromptsJson;
  String? selectedConversationId;

  /// `null` 表示旧数据未配置，运行时按关闭处理。
  bool? contextMessageLimitEnabled;
  int contextMessageLimit;

  /// `null` 表示旧数据未配置，运行时按开启处理以保留既有工具轮次上限。
  bool? toolCallRoundsLimitEnabled;
  int toolCallRoundsLimit;

  /// `null` 表示旧数据未配置，运行时按关闭处理。
  bool? temperatureEnabled;
  double temperature;

  /// `0` 表示不向模型传递 top_p。
  double topP;

  /// `0` 表示不向模型传递 top_k。
  int topK;

  /// `null` 表示旧数据未配置，运行时按开启处理以保留既有记忆写入行为。
  bool? memoryWriteFrequencyEnabled;
  int memoryWriteFrequency;

  /// `null` 表示旧数据未配置，运行时按开启处理。
  bool? showToolMessages;

  /// `null` 表示旧数据未配置，运行时按开启处理。
  bool? showMemoryMessages;

  /// TTS 说话人 ID（VITS / Matcha / Kokoro / Supertonic）。
  int ttsSpeakerId;

  /// TTS 语速（1.0 正常，越大越快）。
  double ttsSpeed;

  /// Pocket TTS 参考音频绝对路径；`null` 时回退模型包内 test_wavs。
  String? ttsReferenceAudioPath;

  /// 用户昵称，供提示词 `{{user}}` 占位替换；`null` 表示未设置。
  String? user;

  @Index()
  DateTime updatedAt;

  AppPreferencesEntity copyWith({
    String? themeModeName,
    String? localeName,
    String? responseModeName,
    Object? customPromptsJson = _unset,
    Object? selectedConversationId = _unset,
    Object? contextMessageLimitEnabled = _unset,
    int? contextMessageLimit,
    Object? toolCallRoundsLimitEnabled = _unset,
    int? toolCallRoundsLimit,
    Object? temperatureEnabled = _unset,
    double? temperature,
    double? topP,
    int? topK,
    Object? memoryWriteFrequencyEnabled = _unset,
    int? memoryWriteFrequency,
    Object? showToolMessages = _unset,
    Object? showMemoryMessages = _unset,
    int? ttsSpeakerId,
    double? ttsSpeed,
    Object? ttsReferenceAudioPath = _unset,
    Object? user = _unset,
    DateTime? updatedAt,
  }) {
    return AppPreferencesEntity(
      id: id,
      themeModeName: themeModeName ?? this.themeModeName,
      localeName: localeName ?? this.localeName,
      responseModeName: responseModeName ?? this.responseModeName,
      customPromptsJson: customPromptsJson == _unset
          ? this.customPromptsJson
          : customPromptsJson as String?,
      selectedConversationId: selectedConversationId == _unset
          ? this.selectedConversationId
          : selectedConversationId as String?,
      contextMessageLimitEnabled: contextMessageLimitEnabled == _unset
          ? this.contextMessageLimitEnabled
          : contextMessageLimitEnabled as bool?,
      contextMessageLimit: contextMessageLimit ?? this.contextMessageLimit,
      toolCallRoundsLimitEnabled: toolCallRoundsLimitEnabled == _unset
          ? this.toolCallRoundsLimitEnabled
          : toolCallRoundsLimitEnabled as bool?,
      toolCallRoundsLimit: toolCallRoundsLimit ?? this.toolCallRoundsLimit,
      temperatureEnabled: temperatureEnabled == _unset
          ? this.temperatureEnabled
          : temperatureEnabled as bool?,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      memoryWriteFrequencyEnabled: memoryWriteFrequencyEnabled == _unset
          ? this.memoryWriteFrequencyEnabled
          : memoryWriteFrequencyEnabled as bool?,
      memoryWriteFrequency: memoryWriteFrequency ?? this.memoryWriteFrequency,
      showToolMessages: showToolMessages == _unset
          ? this.showToolMessages
          : showToolMessages as bool?,
      showMemoryMessages: showMemoryMessages == _unset
          ? this.showMemoryMessages
          : showMemoryMessages as bool?,
      ttsSpeakerId: ttsSpeakerId ?? this.ttsSpeakerId,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ttsReferenceAudioPath: ttsReferenceAudioPath == _unset
          ? this.ttsReferenceAudioPath
          : ttsReferenceAudioPath as String?,
      user: user == _unset ? this.user : user as String?,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();

const appPreferencesEntityId = 'current';

const defaultContextMessageLimit = 64;
const defaultToolCallRoundsLimit = 3;
const defaultTemperature = 1.0;
const defaultTopP = 0.0;
const defaultTopK = 0;
const defaultMemoryWriteFrequency = 1;
const defaultTtsSpeakerId = 0;
const defaultTtsSpeed = 1.0;

const minContextMessageLimit = 1;
const maxContextMessageLimit = 100;
const minToolCallRoundsLimit = 1;
const maxToolCallRoundsLimit = 50;
const minTemperature = 0.0;
const maxTemperature = 2.0;
const minTopP = 0.0;
const maxTopP = 1.0;
const minTopK = 0;
const maxTopK = 50;
const minMemoryWriteFrequency = 1;
const maxMemoryWriteFrequency = 50;
const minTtsSpeakerId = 0;
const maxTtsSpeakerId = 999;
const minTtsSpeed = 0.5;
const maxTtsSpeed = 2.0;

const contextMessageLimitStep = 1.0;
const toolCallRoundsLimitStep = 1.0;
const temperatureStep = 0.01;
const topPStep = 0.01;
const topKStep = 1.0;
const memoryWriteFrequencyStep = 1.0;
const ttsSpeedStep = 0.1;
