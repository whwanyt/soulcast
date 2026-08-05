import 'dart:convert';

import 'package:soulcast/entities/ai_provider/ai_provider.dart';

import '../model/ai_provider_transfer_data.dart';

/// AI 服务商 JSON 的校验错误类型。
enum AiProviderJsonError { invalidJson, invalidFields, missingRequiredField }

/// 携带可本地化错误类型的 AI 服务商 JSON 异常。
class AiProviderJsonException implements Exception {
  const AiProviderJsonException(this.error);

  final AiProviderJsonError error;
}

/// 严格编解码单个 AI 服务商传输 JSON。
class AiProviderJsonCodec {
  const AiProviderJsonCodec();

  static const _requiredKeys = {
    'name',
    'baseUrl',
    'apiPath',
    'apiKey',
    'apiMode',
    'backgroundEnabled',
  };

  String encode(AiProviderTransferData data) {
    return const JsonEncoder.withIndent('  ').convert(data.toJson());
  }

  AiProviderTransferData decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const AiProviderJsonException(AiProviderJsonError.invalidJson);
    }

    if (decoded is! Map<String, dynamic> ||
        decoded.length != _requiredKeys.length ||
        !_requiredKeys.every(decoded.containsKey) ||
        decoded.values.any((value) => value is! String)) {
      throw const AiProviderJsonException(AiProviderJsonError.invalidFields);
    }

    final name = (decoded['name'] as String).trim();
    final baseUrl = (decoded['baseUrl'] as String).trim();
    final apiPath = (decoded['apiPath'] as String).trim();
    final apiKey = (decoded['apiKey'] as String).trim();
    final apiModeRaw = (decoded['apiMode'] as String).trim();
    final backgroundRaw = (decoded['backgroundEnabled'] as String)
        .trim()
        .toLowerCase();
    if (name.isEmpty || baseUrl.isEmpty || apiKey.isEmpty) {
      throw const AiProviderJsonException(
        AiProviderJsonError.missingRequiredField,
      );
    }

    final String apiMode;
    try {
      apiMode = parseAiProviderApiMode(apiModeRaw).name;
    } on FormatException {
      throw const AiProviderJsonException(AiProviderJsonError.invalidFields);
    }

    final bool backgroundEnabled;
    if (backgroundRaw == 'true') {
      backgroundEnabled = true;
    } else if (backgroundRaw == 'false') {
      backgroundEnabled = false;
    } else {
      throw const AiProviderJsonException(AiProviderJsonError.invalidFields);
    }

    return AiProviderTransferData(
      name: name,
      baseUrl: baseUrl,
      apiPath: apiPath,
      apiKey: apiKey,
      apiMode: apiMode,
      backgroundEnabled: backgroundEnabled,
    );
  }
}
