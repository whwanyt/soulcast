part of 'app_preferences_provider.dart';

mixin _AppPreferencesChatActions on _AppPreferencesController {
  Future<void> saveCustomPrompt(PromptId id, String? value) async {
    final nextPrompts = upsertCustomPrompt(state.customPrompts, id, value);
    final nextJson = encodeCustomPrompts(nextPrompts);
    final currentJson = encodeCustomPrompts(state.customPrompts);
    if (nextJson == currentJson) {
      return;
    }

    state = state.copyWith(customPrompts: nextPrompts);
    final repository = await _repository();
    repository.saveCustomPromptsJson(nextJson);
  }

  Future<void> selectConversation(String? conversationId) async {
    if (state.selectedConversationId == conversationId) {
      return;
    }

    state = state.copyWith(selectedConversationId: conversationId);
    final repository = await _repository();
    repository.saveSelectedConversation(conversationId);
  }

  Future<void> saveContextMessageLimit({
    required bool enabled,
    required int limit,
  }) async {
    final normalizedLimit = limit
        .clamp(minContextMessageLimit, maxContextMessageLimit)
        .toInt();
    if (state.contextMessageLimitEnabled == enabled &&
        state.contextMessageLimit == normalizedLimit) {
      return;
    }

    state = state.copyWith(
      contextMessageLimitEnabled: enabled,
      contextMessageLimit: normalizedLimit,
    );
    final repository = await _repository();
    repository.saveContextMessageLimit(
      enabled: enabled,
      limit: normalizedLimit,
    );
  }

  Future<void> saveToolCallRoundsLimit({
    required bool enabled,
    required int limit,
  }) async {
    final normalizedLimit = limit
        .clamp(minToolCallRoundsLimit, maxToolCallRoundsLimit)
        .toInt();
    if (state.toolCallRoundsLimitEnabled == enabled &&
        state.toolCallRoundsLimit == normalizedLimit) {
      return;
    }

    state = state.copyWith(
      toolCallRoundsLimitEnabled: enabled,
      toolCallRoundsLimit: normalizedLimit,
    );
    final repository = await _repository();
    repository.saveToolCallRoundsLimit(
      enabled: enabled,
      limit: normalizedLimit,
    );
  }

  Future<void> saveTemperature({
    required bool enabled,
    required double temperature,
  }) async {
    final normalizedTemperature = (temperature * 100).round() / 100;
    final clampedTemperature = normalizedTemperature
        .clamp(minTemperature, maxTemperature)
        .toDouble();
    if (state.temperatureEnabled == enabled &&
        state.temperature == clampedTemperature) {
      return;
    }

    state = state.copyWith(
      temperatureEnabled: enabled,
      temperature: clampedTemperature,
    );
    final repository = await _repository();
    repository.saveTemperature(
      enabled: enabled,
      temperature: clampedTemperature,
    );
  }

  Future<void> saveTopP(double topP) async {
    final normalized = ((topP * 100).round() / 100)
        .clamp(minTopP, maxTopP)
        .toDouble();
    if (state.topP == normalized) {
      return;
    }

    state = state.copyWith(topP: normalized);
    final repository = await _repository();
    repository.saveTopP(normalized);
  }

  Future<void> saveTopK(int topK) async {
    final normalized = topK.clamp(minTopK, maxTopK).toInt();
    if (state.topK == normalized) {
      return;
    }

    state = state.copyWith(topK: normalized);
    final repository = await _repository();
    repository.saveTopK(normalized);
  }

  Future<void> saveMemoryWriteFrequency({
    required bool enabled,
    required int frequency,
  }) async {
    final normalizedFrequency = frequency
        .clamp(minMemoryWriteFrequency, maxMemoryWriteFrequency)
        .toInt();
    if (state.memoryWriteFrequencyEnabled == enabled &&
        state.memoryWriteFrequency == normalizedFrequency) {
      return;
    }

    state = state.copyWith(
      memoryWriteFrequencyEnabled: enabled,
      memoryWriteFrequency: normalizedFrequency,
    );
    final repository = await _repository();
    repository.saveMemoryWriteFrequency(
      enabled: enabled,
      frequency: normalizedFrequency,
    );
  }

  Future<void> saveShowToolMessages(bool showToolMessages) async {
    if (state.showToolMessages == showToolMessages) {
      return;
    }

    state = state.copyWith(showToolMessages: showToolMessages);
    final repository = await _repository();
    repository.saveShowToolMessages(showToolMessages);
  }

  Future<void> saveShowMemoryMessages(bool showMemoryMessages) async {
    if (state.showMemoryMessages == showMemoryMessages) {
      return;
    }

    state = state.copyWith(showMemoryMessages: showMemoryMessages);
    final repository = await _repository();
    repository.saveShowMemoryMessages(showMemoryMessages);
  }
}
