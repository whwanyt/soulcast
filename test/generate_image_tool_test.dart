import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/agent/api/llm_client.dart';
import 'package:soulcast/features/agent/api/openai_llm_mapper.dart';
import 'package:soulcast/features/agent/model/chat_settings.dart';
import 'package:soulcast/features/agent/model/llm_image_generation.dart';
import 'package:soulcast/features/agent/model/llm_image_request.dart';
import 'package:soulcast/features/agent/model/llm_chat_completion.dart';
import 'package:soulcast/features/agent/model/llm_chat_request.dart';
import 'package:soulcast/features/agent/model/llm_remote_poll_result.dart';
import 'package:soulcast/features/agent/model/llm_stream_snapshot.dart';
import 'package:soulcast/features/agent/model/remote_ai_model.dart';
import 'package:soulcast/features/agent_tools/service/generate_image_tool.dart';
import 'package:soulcast/shared/storage/image_file_store.dart';

void main() {
  group('toLlmImageGeneration', () {
    test('maps url response', () {
      const response = ImageResponse(
        created: 1,
        data: [GeneratedImage(url: 'https://example.com/a.png')],
      );

      final generation = toLlmImageGeneration(response);

      expect(generation, isNotNull);
      expect(generation!.url, 'https://example.com/a.png');
      expect(generation.b64Json, isNull);
    });

    test('maps b64_json response', () {
      const response = ImageResponse(
        created: 1,
        data: [GeneratedImage(b64Json: 'abc123')],
      );

      final generation = toLlmImageGeneration(response);

      expect(generation, isNotNull);
      expect(generation!.url, isNull);
      expect(generation.b64Json, 'abc123');
    });

    test('returns null when neither url nor b64_json exists', () {
      const response = ImageResponse(created: 1, data: [GeneratedImage()]);

      expect(toLlmImageGeneration(response), isNull);
    });
  });

  group('ImageFileStore', () {
    // Minimal valid 1x1 PNG.
    const pngBytes = <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x02,
      0x00,
      0x00,
      0x00,
      0x90,
      0x77,
      0x53,
      0xDE,
      0x00,
      0x00,
      0x00,
      0x0C,
      0x49,
      0x44,
      0x41,
      0x54,
      0x08,
      0xD7,
      0x63,
      0xF8,
      0xCF,
      0xC0,
      0x00,
      0x00,
      0x00,
      0x03,
      0x00,
      0x01,
      0x00,
      0x05,
      0xFE,
      0xD4,
      0xEF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ];

    test('persists png b64_json as local file uri', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'soulcast_gen_image_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final store = ImageFileStore(
        fileNamePrefix: 'gen',
        baseDirectory: tempDir,
      );
      final uri = await store.saveB64Json(
        base64Encode(Uint8List.fromList(pngBytes)),
      );

      expect(uri.scheme, 'file');
      expect(uri.path, endsWith('.png'));
      final file = File(uri.toFilePath());
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), pngBytes);
    });

    test('persists remote url bytes as local file uri', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'soulcast_gen_image_url_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      Uri? downloaded;
      final store = ImageFileStore(
        fileNamePrefix: 'gen',
        baseDirectory: tempDir,
        downloadBytes: (url) async {
          downloaded = url;
          return pngBytes;
        },
      );
      final uri = await store.saveFromUrl('https://cdn.example.com/out.png');

      expect(downloaded, Uri.parse('https://cdn.example.com/out.png'));
      expect(uri.scheme, 'file');
      expect(uri.path, endsWith('.png'));
      final file = File(uri.toFilePath());
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), pngBytes);
    });
  });

  group('GenerateImageTool', () {
    test('persists b64_json and returns file markdown', () async {
      final now = DateTime(2026, 7, 17);
      final model = AiModelEntity(
        id: 'model-1',
        providerId: 'provider-1',
        name: 'Image',
        model: 'gpt-image-1',
        createdAt: now,
        updatedAt: now,
        outputFormats: const [AiModelFormatTags.image],
      );
      final settings = ChatSettings(
        apiKey: 'key',
        baseUrl: 'https://example.com/v1',
        timeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 10),
        maxRetries: 0,
        model: 'gpt-image-1',
      );
      var closed = false;
      Uri? persisted;
      final tool = GenerateImageTool(
        resolveImageModel: () async => model,
        resolveClientSettings: (_) async => settings,
        createClient: (_) => _FakeImageClient(
          generation: const LlmImageGeneration(b64Json: 'cG5n'),
          onClose: () => closed = true,
        ),
        persistB64Json: (b64) async {
          expect(b64, 'cG5n');
          persisted = Uri.file('/tmp/gen.png');
          return persisted!;
        },
      );

      final result = await tool.run(const {'prompt': 'a cat'});

      expect(result['status'], 'success');
      expect(result['url'], 'file:///tmp/gen.png');
      expect(result['markdown'], '![generated image](file:///tmp/gen.png)');
      expect(persisted, isNotNull);
      expect(closed, isTrue);
    });

    test('persists remote url and returns file markdown', () async {
      final now = DateTime(2026, 7, 17);
      final model = AiModelEntity(
        id: 'model-1',
        providerId: 'provider-1',
        name: 'Image',
        model: 'dall-e-3',
        createdAt: now,
        updatedAt: now,
        outputFormats: const [AiModelFormatTags.image],
      );
      final settings = ChatSettings(
        apiKey: 'key',
        baseUrl: 'https://example.com/v1',
        timeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 10),
        maxRetries: 0,
        model: 'dall-e-3',
      );
      String? persistedUrl;
      final tool = GenerateImageTool(
        resolveImageModel: () async => model,
        resolveClientSettings: (_) async => settings,
        createClient: (_) => _FakeImageClient(
          generation: const LlmImageGeneration(
            url: 'https://cdn.example.com/out.png',
          ),
        ),
        persistB64Json: (_) async =>
            fail('should not persist b64 when url exists'),
        persistUrl: (url) async {
          persistedUrl = url;
          return Uri.file('/tmp/gen_from_url.png');
        },
      );

      final result = await tool.run(const {'prompt': 'a dog'});

      expect(result['status'], 'success');
      expect(persistedUrl, 'https://cdn.example.com/out.png');
      expect(result['url'], 'file:///tmp/gen_from_url.png');
      expect(
        result['markdown'],
        '![generated image](file:///tmp/gen_from_url.png)',
      );
    });
  });
}

class _FakeImageClient implements LlmClient {
  _FakeImageClient({required this.generation, this.onClose});

  final LlmImageGeneration generation;
  final void Function()? onClose;

  @override
  Future<LlmChatCompletion> createChatCompletion(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<LlmStreamSnapshot> createChatCompletionStream(
    LlmChatRequest request, {
    Future<void>? abortTrigger,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LlmImageGeneration> createImage(LlmImageRequest request) async {
    return generation;
  }

  @override
  Future<LlmRemotePollResult> pollRemoteResponse(
    String remoteResponseId, {
    Future<void>? abortTrigger,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelRemoteResponse(
    String remoteResponseId, {
    Future<void>? abortTrigger,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<RemoteAiModel>> listModels() async => const [];

  @override
  void close() {
    onClose?.call();
  }
}
