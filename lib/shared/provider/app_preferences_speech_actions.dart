part of 'app_preferences_provider.dart';

mixin _AppPreferencesSpeechActions on _AppPreferencesController {
  Future<void> saveTtsSpeakerId(int speakerId) async {
    final normalized = speakerId
        .clamp(minTtsSpeakerId, maxTtsSpeakerId)
        .toInt();
    if (state.ttsSpeakerId == normalized) {
      return;
    }

    state = state.copyWith(ttsSpeakerId: normalized);
    final repository = await _repository();
    repository.saveTtsSpeakerId(normalized);
  }

  Future<void> saveTtsSpeed(double speed) async {
    final normalized =
        (speed.clamp(minTtsSpeed, maxTtsSpeed) * 10).round() / 10;
    if (state.ttsSpeed == normalized) {
      return;
    }

    state = state.copyWith(ttsSpeed: normalized);
    final repository = await _repository();
    repository.saveTtsSpeed(normalized);
  }

  Future<void> saveTtsReferenceAudioPath(String? path) async {
    final normalized = path?.trim();
    final next = (normalized == null || normalized.isEmpty) ? null : normalized;
    if (state.ttsReferenceAudioPath == next) {
      return;
    }

    state = state.copyWith(ttsReferenceAudioPath: next);
    final repository = await _repository();
    repository.saveTtsReferenceAudioPath(next);
  }

  Future<void> saveUser(String? user) async {
    final normalized = user?.trim();
    final next = (normalized == null || normalized.isEmpty) ? null : normalized;
    if (state.user == next) {
      return;
    }

    state = state.copyWith(user: next);
    PromptCommonTokens.sync(user: state.promptUser);
    final repository = await _repository();
    repository.saveUser(next);
  }
}
