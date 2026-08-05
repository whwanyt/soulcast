part of 'app_preferences_provider.dart';

mixin _AppPreferencesRestore on _AppPreferencesController {
  Future<void> restore() async {
    final repository = await _repository();
    final preferences = repository.ensurePreferences(
      themeModeName: state.themeMode.name,
      localeName: state.locale.name,
      responseModeName: state.responseMode.name,
    );
    final themeMode = AppThemeModePreference.values.firstWhere(
      (mode) => mode.name == preferences.themeModeName,
      orElse: () => state.themeMode,
    );
    final locale = AppLocale.values.firstWhere(
      (locale) => locale.name == preferences.localeName,
      orElse: () => LocaleSettings.currentLocale,
    );
    final responseMode = ChatResponseModePreference.values.firstWhere(
      (mode) => mode.name == preferences.responseModeName,
      orElse: () => state.responseMode,
    );

    await LocaleSettings.setLocale(locale);
    AppBootAppearance.setThemeMode(themeMode.themeMode);
    state = state.copyWith(
      themeMode: themeMode,
      locale: locale,
      responseMode: responseMode,
      customPrompts: decodeCustomPrompts(preferences.customPromptsJson),
      selectedConversationId: preferences.selectedConversationId,
      contextMessageLimitEnabled:
          preferences.contextMessageLimitEnabled ?? false,
      contextMessageLimit: preferences.contextMessageLimit
          .clamp(minContextMessageLimit, maxContextMessageLimit)
          .toInt(),
      toolCallRoundsLimitEnabled:
          preferences.toolCallRoundsLimitEnabled ?? true,
      toolCallRoundsLimit: preferences.toolCallRoundsLimit
          .clamp(minToolCallRoundsLimit, maxToolCallRoundsLimit)
          .toInt(),
      temperatureEnabled: preferences.temperatureEnabled ?? false,
      temperature: preferences.temperature
          .clamp(minTemperature, maxTemperature)
          .toDouble(),
      topP: preferences.topP.clamp(minTopP, maxTopP).toDouble(),
      topK: preferences.topK.clamp(minTopK, maxTopK).toInt(),
      memoryWriteFrequencyEnabled:
          preferences.memoryWriteFrequencyEnabled ?? true,
      memoryWriteFrequency: preferences.memoryWriteFrequency
          .clamp(minMemoryWriteFrequency, maxMemoryWriteFrequency)
          .toInt(),
      showToolMessages: preferences.showToolMessages ?? true,
      showMemoryMessages: preferences.showMemoryMessages ?? true,
      ttsSpeakerId: preferences.ttsSpeakerId
          .clamp(minTtsSpeakerId, maxTtsSpeakerId)
          .toInt(),
      ttsSpeed: preferences.ttsSpeed.clamp(minTtsSpeed, maxTtsSpeed).toDouble(),
      ttsReferenceAudioPath: preferences.ttsReferenceAudioPath,
      user: preferences.user,
    );
    PromptCommonTokens.sync(user: state.promptUser);
  }
}
