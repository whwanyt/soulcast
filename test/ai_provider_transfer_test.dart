import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/transfer_ai_provider/service/ai_provider_json_codec.dart';
import 'package:soulcast/features/transfer_ai_provider/service/ai_provider_transfer_service.dart';

void main() {
  test('provider JSON contains only the six required fields', () async {
    final provider = AiProviderEntity(
      id: 'provider_export',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com',
      apiPath: '/v1',
      apiKey: 'sk-export',
      apiMode: AiProviderApiMode.responses.name,
      backgroundEnabled: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    String? clipboardText;
    final service = AiProviderTransferService(
      clipboardWriter: (text) async => clipboardText = text,
    );

    final exported = await service.exportToClipboard(provider);
    final json = jsonDecode(exported) as Map<String, dynamic>;

    expect(clipboardText, exported);
    expect(json.keys, [
      'name',
      'baseUrl',
      'apiPath',
      'apiKey',
      'apiMode',
      'backgroundEnabled',
    ]);
    expect(json, {
      'name': 'OpenAI',
      'baseUrl': 'https://api.openai.com',
      'apiPath': '/v1',
      'apiKey': 'sk-export',
      'apiMode': 'responses',
      'backgroundEnabled': 'true',
    });
    expect(exported, isNot(contains('provider_export')));
    expect(exported, isNot(contains('models')));
  });

  test('provider JSON decoder rejects extra fields', () {
    const codec = AiProviderJsonCodec();

    expect(
      () => codec.decode(
        '{"name":"OpenAI","baseUrl":"https://api.openai.com",'
        '"apiPath":"/v1","apiKey":"sk-test","apiMode":"chatCompletions",'
        '"backgroundEnabled":"false","id":"provider_1"}',
      ),
      throwsA(
        isA<AiProviderJsonException>().having(
          (error) => error.error,
          'error',
          AiProviderJsonError.invalidFields,
        ),
      ),
    );
  });

  test('provider JSON decoder rejects invalid apiMode', () {
    const codec = AiProviderJsonCodec();

    expect(
      () => codec.decode(
        '{"name":"OpenAI","baseUrl":"https://api.openai.com",'
        '"apiPath":"/v1","apiKey":"sk-test","apiMode":"batch",'
        '"backgroundEnabled":"false"}',
      ),
      throwsA(
        isA<AiProviderJsonException>().having(
          (error) => error.error,
          'error',
          AiProviderJsonError.invalidFields,
        ),
      ),
    );
  });
}
