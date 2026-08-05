import 'package:soulcast/entities/ai_provider/ai_provider.dart';

/// AI 服务商导入导出使用的稳定数据结构。
class AiProviderTransferData {
  const AiProviderTransferData({
    required this.name,
    required this.baseUrl,
    required this.apiPath,
    required this.apiKey,
    required this.apiMode,
    required this.backgroundEnabled,
  });

  factory AiProviderTransferData.fromProvider(AiProviderEntity provider) {
    return AiProviderTransferData(
      name: provider.name,
      baseUrl: provider.baseUrl,
      apiPath: provider.apiPath,
      apiKey: provider.apiKey,
      apiMode: provider.apiModeValue.name,
      backgroundEnabled: provider.backgroundEnabled,
    );
  }

  final String name;
  final String baseUrl;
  final String apiPath;
  final String apiKey;
  final String apiMode;
  final bool backgroundEnabled;

  Map<String, String> toJson() {
    return {
      'name': name,
      'baseUrl': baseUrl,
      'apiPath': apiPath,
      'apiKey': apiKey,
      'apiMode': apiMode,
      'backgroundEnabled': backgroundEnabled ? 'true' : 'false',
    };
  }
}
