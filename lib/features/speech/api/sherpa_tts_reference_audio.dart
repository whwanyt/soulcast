part of 'sherpa_offline_tts.dart';

/// 列出模型包内可用的参考 wav（供设置页展示）。
List<String> listBundledTtsReferenceWavs(String modelDir) {
  final dir = Directory(modelDir);
  if (!dir.existsSync()) {
    return const [];
  }
  final wavs = <String>[];
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    if (p.extension(entity.path).toLowerCase() == '.wav') {
      wavs.add(entity.path);
    }
  }
  wavs.sort((a, b) {
    final aBria = p.basename(a).toLowerCase() == 'bria.wav';
    final bBria = p.basename(b).toLowerCase() == 'bria.wav';
    if (aBria != bBria) {
      return aBria ? -1 : 1;
    }
    return a.compareTo(b);
  });
  return wavs;
}
