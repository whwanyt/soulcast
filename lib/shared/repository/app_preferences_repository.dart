import 'package:isar_plus/isar_plus.dart';
import 'package:soulcast/shared/model/app_preferences_entity.dart';

/// 应用偏好的单记录持久化仓库。
///
/// 所有更新都在 Isar 写事务中基于当前记录生成新值，并刷新更新时间。
class AppPreferencesRepository {
  const AppPreferencesRepository(this._isar);

  final Isar _isar;

  /// 返回现有偏好；首次启动时使用给定运行态默认值创建记录。
  AppPreferencesEntity ensurePreferences({
    required String themeModeName,
    required String localeName,
    required String responseModeName,
  }) {
    final existing = _getPreferences();
    if (existing != null) {
      return existing;
    }

    final preferences = AppPreferencesEntity(
      id: appPreferencesEntityId,
      themeModeName: themeModeName,
      localeName: localeName,
      responseModeName: responseModeName,
      contextMessageLimitEnabled: false,
      contextMessageLimit: defaultContextMessageLimit,
      toolCallRoundsLimitEnabled: true,
      toolCallRoundsLimit: defaultToolCallRoundsLimit,
      temperatureEnabled: false,
      temperature: defaultTemperature,
      topP: defaultTopP,
      topK: defaultTopK,
      memoryWriteFrequencyEnabled: true,
      memoryWriteFrequency: defaultMemoryWriteFrequency,
      showToolMessages: true,
      showMemoryMessages: true,
      ttsSpeakerId: defaultTtsSpeakerId,
      ttsSpeed: defaultTtsSpeed,
      ttsReferenceAudioPath: null,
      user: null,
      updatedAt: DateTime.now(),
    );
    _isar.write((isar) {
      isar.collection<String, AppPreferencesEntity>().put(preferences);
    });
    return preferences;
  }

  AppPreferencesEntity saveThemeMode(String themeModeName) {
    return _update((current) => current.copyWith(themeModeName: themeModeName));
  }

  AppPreferencesEntity saveLocale(String localeName) {
    return _update((current) => current.copyWith(localeName: localeName));
  }

  AppPreferencesEntity saveResponseMode(String responseModeName) {
    return _update(
      (current) => current.copyWith(responseModeName: responseModeName),
    );
  }

  AppPreferencesEntity saveCustomPromptsJson(String? customPromptsJson) {
    return _update(
      (current) => current.copyWith(customPromptsJson: customPromptsJson),
    );
  }

  AppPreferencesEntity saveSelectedConversation(String? conversationId) {
    return _update(
      (current) => current.copyWith(selectedConversationId: conversationId),
    );
  }

  AppPreferencesEntity saveContextMessageLimit({
    required bool enabled,
    required int limit,
  }) {
    return _update(
      (current) => current.copyWith(
        contextMessageLimitEnabled: enabled,
        contextMessageLimit: limit.clamp(
          minContextMessageLimit,
          maxContextMessageLimit,
        ),
      ),
    );
  }

  AppPreferencesEntity saveToolCallRoundsLimit({
    required bool enabled,
    required int limit,
  }) {
    return _update(
      (current) => current.copyWith(
        toolCallRoundsLimitEnabled: enabled,
        toolCallRoundsLimit: limit.clamp(
          minToolCallRoundsLimit,
          maxToolCallRoundsLimit,
        ),
      ),
    );
  }

  AppPreferencesEntity saveTemperature({
    required bool enabled,
    required double temperature,
  }) {
    return _update(
      (current) => current.copyWith(
        temperatureEnabled: enabled,
        temperature: temperature.clamp(minTemperature, maxTemperature),
      ),
    );
  }

  AppPreferencesEntity saveTopP(double topP) {
    return _update(
      (current) => current.copyWith(topP: topP.clamp(minTopP, maxTopP)),
    );
  }

  AppPreferencesEntity saveTopK(int topK) {
    return _update(
      (current) => current.copyWith(topK: topK.clamp(minTopK, maxTopK)),
    );
  }

  AppPreferencesEntity saveMemoryWriteFrequency({
    required bool enabled,
    required int frequency,
  }) {
    return _update(
      (current) => current.copyWith(
        memoryWriteFrequencyEnabled: enabled,
        memoryWriteFrequency: frequency.clamp(
          minMemoryWriteFrequency,
          maxMemoryWriteFrequency,
        ),
      ),
    );
  }

  AppPreferencesEntity saveShowToolMessages(bool showToolMessages) {
    return _update(
      (current) => current.copyWith(showToolMessages: showToolMessages),
    );
  }

  AppPreferencesEntity saveShowMemoryMessages(bool showMemoryMessages) {
    return _update(
      (current) => current.copyWith(showMemoryMessages: showMemoryMessages),
    );
  }

  AppPreferencesEntity saveTtsSpeakerId(int speakerId) {
    return _update(
      (current) => current.copyWith(
        ttsSpeakerId: speakerId.clamp(minTtsSpeakerId, maxTtsSpeakerId),
      ),
    );
  }

  AppPreferencesEntity saveTtsSpeed(double speed) {
    return _update(
      (current) =>
          current.copyWith(ttsSpeed: speed.clamp(minTtsSpeed, maxTtsSpeed)),
    );
  }

  AppPreferencesEntity saveTtsReferenceAudioPath(String? path) {
    return _update((current) => current.copyWith(ttsReferenceAudioPath: path));
  }

  AppPreferencesEntity saveUser(String? user) {
    return _update((current) => current.copyWith(user: user));
  }

  AppPreferencesEntity _update(
    AppPreferencesEntity Function(AppPreferencesEntity current) builder,
  ) {
    late AppPreferencesEntity preferences;
    _isar.write((isar) {
      final collection = isar.collection<String, AppPreferencesEntity>();
      // 即使调用方早于启动恢复流程写入偏好，也要保证单例记录存在。
      final current =
          collection.get(appPreferencesEntityId) ??
          AppPreferencesEntity(
            id: appPreferencesEntityId,
            themeModeName: _defaultThemeModeName,
            localeName: _defaultLocaleName,
            responseModeName: _defaultResponseModeName,
            contextMessageLimitEnabled: false,
            contextMessageLimit: defaultContextMessageLimit,
            toolCallRoundsLimitEnabled: true,
            toolCallRoundsLimit: defaultToolCallRoundsLimit,
            temperatureEnabled: false,
            temperature: defaultTemperature,
            topP: defaultTopP,
            topK: defaultTopK,
            memoryWriteFrequencyEnabled: true,
            memoryWriteFrequency: defaultMemoryWriteFrequency,
            showToolMessages: true,
            showMemoryMessages: true,
            ttsSpeakerId: defaultTtsSpeakerId,
            ttsSpeed: defaultTtsSpeed,
            ttsReferenceAudioPath: null,
            user: null,
            updatedAt: DateTime.now(),
          );
      preferences = builder(current).copyWith(updatedAt: DateTime.now());
      collection.put(preferences);
    });
    return preferences;
  }

  AppPreferencesEntity? _getPreferences() {
    return _isar.collection<String, AppPreferencesEntity>().get(
      appPreferencesEntityId,
    );
  }
}

const _defaultThemeModeName = 'system';
const _defaultLocaleName = 'zhCn';
const _defaultResponseModeName = 'stream';
