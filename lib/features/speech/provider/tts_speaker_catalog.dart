import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';

import '../model/tts_speaker.dart';
import '../service/tts_speaker_catalog_service.dart';

part 'tts_speaker_catalog.g.dart';

/// 解析当前默认 TTS 模型可用的说话人目录。
@Riverpod(keepAlive: true)
Future<List<TtsSpeaker>> ttsSpeakerCatalog(Ref ref) async {
  final model = ref.watch(defaultTtsSpeechModelProvider);
  final localDir = model?.localDir ?? '';
  return const TtsSpeakerCatalogService().listSpeakers(localDir);
}
