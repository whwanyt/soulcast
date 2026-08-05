import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/transfer_ai_provider/transfer_ai_provider.dart';
import 'package:soulcast/features/transfer_ai_provider/service/ai_provider_transfer_service.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/provider_detail/provider_detail_page.dart';
import 'package:soulcast/pages/provider_settings/provider_settings_page.dart';

void main() {
  testWidgets('Provider settings page exposes provider list and add action', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            aiProvidersProvider.overrideWith(
              (ref) => Stream.value(const <AiProviderEntity>[]),
            ),
          ],
          child: const MaterialApp(home: ProviderSettingsPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(t.providerSettings.title), findsOneWidget);
    expect(find.text(t.providerSettings.noProviders), findsOneWidget);
    expect(find.text(t.providerSettings.addProvider), findsOneWidget);
    expect(find.byTooltip(t.providerSettings.newProvider), findsOneWidget);
    expect(find.byTooltip(t.providerSettings.importProvider), findsOneWidget);
    expect(find.text(t.providerSettings.providerTab), findsNothing);
    expect(find.text(t.providerSettings.modelsTab), findsNothing);
  });

  testWidgets('Provider settings imports provider JSON from bottom sheet', (
    tester,
  ) async {
    final repository = _FakeAiProviderRepository();

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            aiProvidersProvider.overrideWith(
              (ref) => Stream.value(const <AiProviderEntity>[]),
            ),
            aiProviderRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
          ],
          child: const MaterialApp(home: ProviderSettingsPage()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip(t.providerSettings.importProvider));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AiProviderImportSheet), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('ai_provider_import_json_field')),
        matching: find.byType(TextFormField),
      ),
      '{"name":"OpenRouter","baseUrl":"https://openrouter.ai/",'
      '"apiPath":"api/v1/","apiKey":"sk-import",'
      '"apiMode":"responses","backgroundEnabled":"true"}',
    );
    await tester.tap(
      find.widgetWithText(
        FilledButton,
        t.providerSettings.importProviderConfirm,
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.providers, hasLength(1));
    expect(repository.providers.single.name, 'OpenRouter');
    expect(repository.providers.single.baseUrl, 'https://openrouter.ai/');
    expect(repository.providers.single.apiPath, 'api/v1/');
    expect(repository.providers.single.apiKey, 'sk-import');
    expect(repository.providers.single.apiMode, 'responses');
    expect(repository.providers.single.backgroundEnabled, isTrue);
    expect(find.byType(BottomSheet), findsNothing);
    // SmartDialog toast 不在常规 widget 树中，导入结果以 repository 为准。
  });

  testWidgets('Provider import sheet keeps invalid JSON visible', (
    tester,
  ) async {
    final repository = _FakeAiProviderRepository();

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            aiProvidersProvider.overrideWith(
              (ref) => Stream.value(const <AiProviderEntity>[]),
            ),
            aiProviderRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
          ],
          child: const MaterialApp(home: ProviderSettingsPage()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip(t.providerSettings.importProvider));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('ai_provider_import_json_field')),
        matching: find.byType(TextFormField),
      ),
      '{invalid json}',
    );
    await tester.tap(
      find.widgetWithText(
        FilledButton,
        t.providerSettings.importProviderConfirm,
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.providers, isEmpty);
    expect(find.byType(AiProviderImportSheet), findsOneWidget);
    expect(
      find.text(t.providerSettings.importProviderInvalidJson),
      findsOneWidget,
    );
  });

  testWidgets('Provider settings page renders saved providers', (tester) async {
    final now = DateTime(2026);
    final provider = AiProviderEntity(
      id: 'provider_openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com',
      apiPath: '/v1',
      apiKey: 'sk-test',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            aiProvidersProvider.overrideWith((ref) => Stream.value([provider])),
          ],
          child: const MaterialApp(home: ProviderSettingsPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('https://api.openai.com/v1'), findsOneWidget);
    expect(find.text(t.providerSettings.noProviders), findsNothing);
  });

  testWidgets('Provider detail page exposes provider and model tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            aiProvidersProvider.overrideWith(
              (ref) => Stream.value(const <AiProviderEntity>[]),
            ),
          ],
          child: const MaterialApp(home: ProviderDetailPage(providerId: null)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(t.providerSettings.newProvider), findsOneWidget);
    expect(find.text(t.providerSettings.providerTab), findsOneWidget);
    expect(find.text(t.providerSettings.modelsTab), findsOneWidget);
    expect(find.text(t.providerSettings.providerName), findsOneWidget);
    expect(find.text(t.providerSettings.baseUrl), findsOneWidget);
    expect(find.text(t.providerSettings.apiPath), findsOneWidget);
    expect(find.text(t.providerSettings.addProvider), findsOneWidget);
    expect(find.byTooltip(t.providerSettings.showApiKey), findsOneWidget);
    expect(find.byTooltip(t.providerSettings.exportProvider), findsNothing);
  });

  testWidgets('Provider detail exports only provider fields to clipboard', (
    tester,
  ) async {
    final now = DateTime(2026);
    final provider = AiProviderEntity(
      id: 'provider_clipboard',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      apiPath: '/v1',
      apiKey: 'sk-deepseek',
      createdAt: now,
      updatedAt: now,
    );
    String? clipboardText;
    final transferService = AiProviderTransferService(
      clipboardWriter: (text) async => clipboardText = text,
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            aiProvidersProvider.overrideWith((ref) => Stream.value([provider])),
            aiProviderModelsProvider.overrideWith(
              (ref, providerId) => Stream.value(const <AiModelEntity>[]),
            ),
            aiProviderTransferServiceProvider.overrideWithValue(
              transferService,
            ),
          ],
          child: const MaterialApp(
            home: ProviderDetailPage(providerId: 'provider_clipboard'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(t.providerSettings.exportProvider));
    await tester.pump();

    expect(jsonDecode(clipboardText!) as Map<String, dynamic>, {
      'name': 'DeepSeek',
      'baseUrl': 'https://api.deepseek.com',
      'apiPath': '/v1',
      'apiKey': 'sk-deepseek',
      'apiMode': 'chatCompletions',
      'backgroundEnabled': 'false',
    });
    // SmartDialog toast 不在常规 widget 树中，导出结果以剪贴板内容为准。
  });

  testWidgets('Provider detail page toggles API key visibility', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            aiProvidersProvider.overrideWith(
              (ref) => Stream.value(const <AiProviderEntity>[]),
            ),
          ],
          child: const MaterialApp(home: ProviderDetailPage(providerId: null)),
        ),
      ),
    );
    await tester.pump();

    EditableText apiKeyEditableText() {
      final fieldFinder = find.ancestor(
        of: find.text(t.providerSettings.apiKey),
        matching: find.byType(TextFormField),
      );
      return tester.widget<EditableText>(
        find.descendant(of: fieldFinder, matching: find.byType(EditableText)),
      );
    }

    expect(apiKeyEditableText().obscureText, isTrue);

    await tester.tap(find.byTooltip(t.providerSettings.showApiKey));
    await tester.pump();

    expect(find.byTooltip(t.providerSettings.hideApiKey), findsOneWidget);
    expect(apiKeyEditableText().obscureText, isFalse);
  });

  testWidgets('Provider detail model tab adds model from bottom sheet', (
    tester,
  ) async {
    final now = DateTime(2026);
    final provider = AiProviderEntity(
      id: 'provider_deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      apiKey: 'token',
      createdAt: now,
      updatedAt: now,
    );
    final repository = _FakeAiProviderRepository(providers: [provider]);

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            aiProvidersProvider.overrideWith((ref) => Stream.value([provider])),
            aiProviderModelsProvider.overrideWith(
              (ref, providerId) => Stream.value(const <AiModelEntity>[]),
            ),
            aiProviderRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
          ],
          child: const MaterialApp(
            home: ProviderDetailPage(providerId: 'provider_deepseek'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.providerSettings.modelsTab));
    await tester.pumpAndSettle();

    expect(find.text(t.providerSettings.noModels), findsOneWidget);
    expect(find.text(t.providerSettings.addModel), findsOneWidget);
    expect(find.text(t.providerSettings.fetchModels), findsOneWidget);

    await tester.tap(find.text(t.providerSettings.addModel));
    await tester.pumpAndSettle();

    expect(find.text(t.providerSettings.addModel), findsWidgets);
    await tester.enterText(find.byType(TextFormField).at(0), 'DeepSeek Chat');
    await tester.enterText(find.byType(TextFormField).at(1), 'deepseek-chat');
    await tester.tap(
      find.widgetWithText(FilledButton, t.providerSettings.addModel).last,
    );
    await tester.pumpAndSettle();

    expect(repository.models, hasLength(1));
    expect(repository.models.single.name, 'DeepSeek Chat');
    expect(repository.models.single.model, 'deepseek-chat');
  });

  testWidgets('Provider detail fetches remote models and skips duplicates', (
    tester,
  ) async {
    final now = DateTime(2026);
    final provider = AiProviderEntity(
      id: 'provider_deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      apiKey: 'token',
      createdAt: now,
      updatedAt: now,
    );
    final existingModel = AiModelEntity(
      id: 'model_flash',
      providerId: provider.id,
      name: 'deepseek-v4-flash',
      model: 'deepseek-v4-flash',
      createdAt: now,
      updatedAt: now,
    );
    final repository = _FakeAiProviderRepository(
      providers: [provider],
      models: [existingModel],
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            aiProvidersProvider.overrideWith((ref) => Stream.value([provider])),
            aiProviderModelsProvider.overrideWith(
              (ref, providerId) => Stream.value([existingModel]),
            ),
            aiProviderRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
            remoteAiModelServiceProvider.overrideWithValue(
              const _FakeRemoteAiModelService([
                RemoteAiModel(
                  id: 'deepseek-v4-flash',
                  object: 'model',
                  ownedBy: 'deepseek',
                ),
                RemoteAiModel(
                  id: 'deepseek-v4-pro',
                  object: 'model',
                  ownedBy: 'deepseek',
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: ProviderDetailPage(providerId: 'provider_deepseek'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.providerSettings.modelsTab));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.providerSettings.fetchModels));
    await tester.pumpAndSettle();

    expect(find.text(t.providerSettings.fetchModelsTitle), findsOneWidget);
    expect(find.text('deepseek-v4-flash'), findsWidgets);
    expect(find.text('deepseek-v4-pro'), findsOneWidget);
    expect(find.text(t.providerSettings.modelAdded), findsOneWidget);
    expect(find.text(t.providerSettings.importModel), findsOneWidget);

    await tester.tap(find.text(t.providerSettings.importModel));
    await tester.pumpAndSettle();

    expect(
      repository.models.where((model) => model.model == 'deepseek-v4-flash'),
      hasLength(1),
    );
    expect(
      repository.models.where((model) => model.model == 'deepseek-v4-pro'),
      hasLength(1),
    );
    expect(find.text(t.providerSettings.modelAdded), findsWidgets);
  });
}

class _FakeAiProviderRepository implements AiProviderRepository {
  _FakeAiProviderRepository({
    List<AiProviderEntity> providers = const [],
    List<AiModelEntity> models = const [],
  }) : providers = [...providers],
       models = [...models];

  final List<AiProviderEntity> providers;
  final List<AiModelEntity> models;
  int _providerCounter = 0;
  int _modelCounter = 0;

  @override
  List<AiProviderEntity> getProviders() => [...providers];

  @override
  Stream<List<AiProviderEntity>> watchProviders() {
    return Stream.value(getProviders());
  }

  @override
  AiProviderEntity? getProvider(String providerId) {
    return providers.where((provider) => provider.id == providerId).firstOrNull;
  }

  @override
  AiProviderEntity upsertProvider({
    String? providerId,
    required String name,
    required String baseUrl,
    required String apiPath,
    required String apiKey,
    String apiMode = 'chatCompletions',
    bool backgroundEnabled = false,
  }) {
    final now = DateTime(2026);
    final id = providerId ?? createProviderId();
    final existingIndex = providers.indexWhere((provider) => provider.id == id);
    final provider = AiProviderEntity(
      id: id,
      name: name.trim(),
      baseUrl: baseUrl.trim(),
      apiPath: apiPath.trim(),
      apiKey: apiKey.trim(),
      apiMode: apiMode,
      backgroundEnabled:
          apiMode == AiProviderApiMode.responses.name && backgroundEnabled,
      createdAt: existingIndex == -1 ? now : providers[existingIndex].createdAt,
      updatedAt: now,
    );
    if (existingIndex == -1) {
      providers.add(provider);
    } else {
      providers[existingIndex] = provider;
    }
    return provider;
  }

  @override
  bool deleteProvider(String providerId) {
    final removedProviders = providers
        .where((provider) => provider.id == providerId)
        .toList();
    providers.removeWhere((provider) => provider.id == providerId);
    models.removeWhere((model) => model.providerId == providerId);
    return removedProviders.isNotEmpty;
  }

  @override
  List<AiModelEntity> getModels({String? providerId}) {
    return models
        .where((model) => providerId == null || model.providerId == providerId)
        .toList();
  }

  @override
  Stream<List<AiModelEntity>> watchModels({String? providerId}) {
    return Stream.value(getModels(providerId: providerId));
  }

  @override
  AiModelEntity? getModel(String modelId) {
    return models.where((model) => model.id == modelId).firstOrNull;
  }

  @override
  AiModelEntity upsertModel({
    String? modelId,
    required String providerId,
    required String name,
    required String model,
    bool isEnabled = true,
    List<String> inputFormats = const [],
    List<String> outputFormats = const [],
  }) {
    final now = DateTime(2026);
    final id = modelId ?? createModelId();
    final existingIndex = models.indexWhere((item) => item.id == id);
    final entity = AiModelEntity(
      id: id,
      providerId: providerId,
      name: name.trim(),
      model: model.trim(),
      isEnabled: isEnabled,
      inputFormats: inputFormats,
      outputFormats: outputFormats,
      createdAt: existingIndex == -1 ? now : models[existingIndex].createdAt,
      updatedAt: now,
    );
    if (existingIndex == -1) {
      models.add(entity);
    } else {
      models[existingIndex] = entity;
    }
    return entity;
  }

  @override
  void setModelEnabled({required String modelId, required bool isEnabled}) {
    final index = models.indexWhere((model) => model.id == modelId);
    if (index == -1) {
      return;
    }
    models[index] = models[index].copyWith(isEnabled: isEnabled);
  }

  @override
  bool deleteModel(String modelId) {
    final removedModels = models.where((model) => model.id == modelId).toList();
    models.removeWhere((model) => model.id == modelId);
    return removedModels.isNotEmpty;
  }

  @override
  String createProviderId() {
    _providerCounter += 1;
    return 'provider_fake_$_providerCounter';
  }

  @override
  String createModelId() {
    _modelCounter += 1;
    return 'model_fake_$_modelCounter';
  }
}

class _FakeRemoteAiModelService extends RemoteAiModelService {
  const _FakeRemoteAiModelService(this.models);

  final List<RemoteAiModel> models;

  @override
  Future<List<RemoteAiModel>> fetchModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    return models;
  }
}
