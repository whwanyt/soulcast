import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';

import '../model/speech_input_state.dart';
import '../service/speech_input_session.dart';

part 'speech_input.g.dart';

/// 管理语音输入 session 生命周期并向 UI 暴露识别状态。
@Riverpod(keepAlive: true)
class SpeechInput extends _$SpeechInput {
  SpeechInputSession? _session;

  @override
  SpeechInputState build() {
    final session = SpeechInputSession(
      loadDefaultModel: () async {
        final repository = await ref.read(speechModelRepositoryProvider.future);
        return repository.getDefault();
      },
    );
    session.onStateChanged = (next) {
      if (!ref.mounted) {
        return;
      }
      state = next;
    };
    _session = session;
    ref.onDispose(() {
      session.onStateChanged = null;
      session.dispose();
    });
    return session.state;
  }

  Future<void> toggleListening() async {
    await _session?.toggle();
  }

  Future<String> stopListening() async {
    return await _session?.stop() ?? '';
  }
}
