import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';

import '../model/speech_output_state.dart';
import '../service/speech_output_session.dart';

part 'speech_output.g.dart';

/// 管理语音合成与播放 session，并统一反馈运行错误。
@Riverpod(keepAlive: true)
class SpeechOutput extends _$SpeechOutput {
  SpeechOutputSession? _session;

  @override
  SpeechOutputState build() {
    final session = SpeechOutputSession(
      loadDefaultModel: () async {
        final repository = await ref.read(speechModelRepositoryProvider.future);
        return repository.getDefault(kind: SpeechModelKind.tts);
      },
      loadVoiceOptions: () async {
        final prefs = ref.read(appPreferencesProvider);
        return (
          sid: prefs.ttsSpeakerId,
          speed: prefs.ttsSpeed,
          referencePath: prefs.ttsReferenceAudioPath,
        );
      },
    );
    session.onStateChanged = (next) {
      if (!ref.mounted) {
        return;
      }
      final previousError = state.errorMessage;
      state = next;
      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty &&
          next.errorMessage != previousError) {
        SmartDialog.showToast(next.errorMessage!);
      }
    };
    _session = session;
    ref.onDispose(() {
      session.onStateChanged = null;
      session.dispose();
    });
    return session.state;
  }

  Future<void> toggle({required String messageId, required String text}) async {
    await _session?.toggle(messageId: messageId, text: text);
  }

  Future<void> stop() async {
    await _session?.stop();
  }
}
