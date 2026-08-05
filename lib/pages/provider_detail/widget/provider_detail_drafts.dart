part of 'provider_detail_widgets.dart';

/// 服务商表单提交前的数据草稿。
class ProviderDetailProviderDraft {
  const ProviderDetailProviderDraft({
    required this.providerId,
    required this.name,
    required this.baseUrl,
    required this.apiPath,
    required this.apiKey,
    this.apiMode = 'chatCompletions',
    this.backgroundEnabled = false,
  });

  final String? providerId;
  final String name;
  final String baseUrl;
  final String apiPath;
  final String apiKey;
  final String apiMode;
  final bool backgroundEnabled;
}

/// 模型表单提交前的数据草稿。
class ProviderDetailModelDraft {
  const ProviderDetailModelDraft({
    required this.modelId,
    required this.name,
    required this.model,
    required this.isEnabled,
    this.inputFormats = const [],
    this.outputFormats = const [],
  });

  final String? modelId;
  final String name;
  final String model;
  final bool isEnabled;
  final List<String> inputFormats;
  final List<String> outputFormats;
}
