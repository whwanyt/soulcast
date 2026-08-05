import 'package:flutter/services.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';

import '../model/ai_provider_transfer_data.dart';
import 'ai_provider_json_codec.dart';

/// AI 服务商 JSON 的剪贴板写入 Port。
typedef AiProviderClipboardWriter = Future<void> Function(String text);

/// 编排 AI 服务商配置的剪贴板导出与 JSON 导入。
class AiProviderTransferService {
  const AiProviderTransferService({
    this.codec = const AiProviderJsonCodec(),
    this.clipboardWriter = _writeClipboard,
  });

  final AiProviderJsonCodec codec;
  final AiProviderClipboardWriter clipboardWriter;

  Future<String> exportToClipboard(AiProviderEntity provider) async {
    final json = codec.encode(AiProviderTransferData.fromProvider(provider));
    await clipboardWriter(json);
    return json;
  }

  AiProviderEntity importFromJson({
    required String json,
    required AiProviderRepository repository,
  }) {
    final data = codec.decode(json);
    return repository.upsertProvider(
      name: data.name,
      baseUrl: data.baseUrl,
      apiPath: data.apiPath,
      apiKey: data.apiKey,
      apiMode: data.apiMode,
      backgroundEnabled: data.backgroundEnabled,
    );
  }
}

Future<void> _writeClipboard(String text) {
  return Clipboard.setData(ClipboardData(text: text));
}
