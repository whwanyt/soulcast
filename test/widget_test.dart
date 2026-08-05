import 'package:flute_core/app/action/app_start_action.dart';
import 'package:flute_core/app/repository.dart';
import 'package:flute_core/app/widgets/app_start_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/app/bootstrap/application.dart';
import 'package:soulcast/app/bootstrap/data/app_state.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/agent_tools/service/current_time_tool.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/model/app_preferences_entity.dart';
import 'package:soulcast/shared/prompt/prompt.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/storage/isar_database.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    registerAppIsarSchemas([
      AppPreferencesEntitySchema,
      AiProviderEntitySchema,
      AiModelEntitySchema,
      ChatConversationEntitySchema,
      ChatConversationMemoryEntitySchema,
      ChatMessageEntitySchema,
      CharacterEntitySchema,
    ]);
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      AppStartScope<AppState>(
        repository: const _FakeStartRepository(),
        appStartAction: const _NoopStartAction(),
        minStartDurationMs: 0,
        child: TranslationProvider(child: const MyApp()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byType(MyApp), findsOneWidget);
  });

  test('Chat provider requires model before sending', () async {
    final container = ProviderContainer.test();

    await container.read(chatProvider.notifier).sendMessage('你好');

    final state = container.read(chatProvider);
    expect(state.messages, isEmpty);
    expect(state.isSending, isFalse);
    expect(state.errorMessage, t.chat.error.missingModel);
  });

  test('Current time tool returns time payload', () async {
    const tool = CurrentTimeTool();

    final result = await tool.run(const {});

    expect(result['localIso8601'], isA<String>());
    expect(result['utcIso8601'], isA<String>());
    expect(result['timeZoneOffsetMinutes'], isA<int>());
    expect(result['timestampMilliseconds'], isA<int>());
  });

  test('Agent tools include current time, location, map, and weather', () {
    final container = ProviderContainer.test();

    final toolNames = container
        .read(agentToolsProvider)
        .map((tool) => tool.name)
        .toList();

    expect(toolNames, contains(AgentToolIds.currentTime));
    expect(toolNames, contains(AgentToolIds.currentLocation));
    expect(toolNames, contains(AgentToolIds.showLocationMap));
    expect(toolNames, contains(AgentToolIds.showWeather));
  });

  test('Disabled agent tools are removed from AI requests', () {
    final container = ProviderContainer.test();

    container
        .read(agentToolConfigsProvider.notifier)
        .setEnabled(AgentToolIds.currentLocation, isEnabled: false);

    final toolNames = container
        .read(agentToolsProvider)
        .map((tool) => tool.name)
        .toList();
    expect(toolNames, contains(AgentToolIds.currentTime));
    expect(toolNames, isNot(contains(AgentToolIds.currentLocation)));
  });

  test('App preferences state records active app settings', () {
    final preferences =
        const AppPreferencesState(
          themeMode: AppThemeModePreference.light,
          locale: AppLocale.zhCn,
          responseMode: ChatResponseModePreference.stream,
        ).copyWith(
          selectedConversationId: 'chat_active',
          customPrompts: {PromptId.appSystem.storageKey: '保持简洁'},
          themeMode: AppThemeModePreference.dark,
          locale: AppLocale.en,
        );

    expect(preferences.selectedConversationId, 'chat_active');
    expect(preferences.customPrompt(PromptId.appSystem), '保持简洁');
    expect(preferences.themeMode, AppThemeModePreference.dark);
    expect(preferences.locale, AppLocale.en);
    expect(preferences.responseMode, ChatResponseModePreference.stream);
  });

  test('Chat state keeps draft message', () {
    final state = const ChatState().copyWith(
      selectedConversationId: 'chat_draft',
      selectedModelId: 'model_chat',
      draftMessage: '切换前未发送',
    );

    expect(state.selectedConversationId, 'chat_draft');
    expect(state.selectedModelId, 'model_chat');
    expect(state.draftMessage, '切换前未发送');
  });

  test('Chat state clears selected conversation messages', () {
    final state = ChatState(
      selectedConversationId: 'chat_active',
      messages: [ChatConversationMessage.user('需要清空')],
      draftMessage: '未发送草稿',
      isSending: true,
      errorMessage: '旧错误',
      lastUsage: const ChatUsageSnapshot(
        promptTokens: 1,
        completionTokens: 2,
        totalTokens: 3,
      ),
    );

    final clearedState = state.clearedConversationMessages('chat_active');
    final untouchedState = state.clearedConversationMessages('chat_other');

    expect(clearedState.messages, isEmpty);
    expect(clearedState.draftMessage, isEmpty);
    expect(clearedState.isSending, isFalse);
    expect(clearedState.errorMessage, isNull);
    expect(clearedState.lastUsage, isNull);
    expect(untouchedState, same(state));
  });
}

class _FakeStartRepository implements AppStartRepository<AppState> {
  const _FakeStartRepository();

  @override
  Future<AppState> initApp() async => const AppState(0);

  @override
  Future<void> fixError(Object error, {Object? extra}) async {}
}

class _NoopStartAction implements AppStartAction<AppState> {
  const _NoopStartAction();

  @override
  void onLoaded(
    BuildContext context,
    WidgetRef ref,
    int cost,
    AppState state,
  ) {}

  @override
  void onStartError(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace trace,
  ) {}

  @override
  void onStartSuccess(BuildContext context, WidgetRef ref, AppState state) {}
}
