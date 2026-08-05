import 'dart:async';
import 'dart:ui';

import 'package:flute_core/app/widgets/app_start_listener.dart';
import 'package:flute_core/app/repository.dart';
import 'package:flute_core/app/starter_mixin.dart';
import 'package:flute_core/log/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/app/theme/app_theme.dart';
import 'package:soulcast/entities/agent_tool/agent_tool.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';
import 'package:soulcast/entities/world_book/world_book.dart';
import 'package:soulcast/entities/speech_model/speech_model.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/mcp/mcp.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/model/app_preferences_entity.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/storage/isar_database.dart';
import 'package:soulcast/shared/theme/app_boot_appearance.dart';

import 'data/app_state.dart';
import 'start_repository.dart';

/// 应用启动编排入口，注册 schema、全局错误处理与启动后恢复任务。
class Application with AppStarter<AppState> {
  Application() {
    registerAppIsarSchemas([
      AppPreferencesEntitySchema,
      AiProviderEntitySchema,
      AiModelEntitySchema,
      ChatConversationEntitySchema,
      ChatConversationMemoryEntitySchema,
      ChatMessageEntitySchema,
      CharacterEntitySchema,
      WorldBookEntitySchema,
      WorldBookEntryEntitySchema,
      AgentToolConfigEntitySchema,
      McpServerConfigEntitySchema,
      SpeechModelEntitySchema,
    ]);
    FlutterError.onError = (details) {
      Log.e(
        'Flutter framework error: ${details.exceptionAsString()}',
        tag: 'START',
        error: details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      Log.e(
        'Platform dispatcher error: $error',
        tag: 'START',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
  }

  @override
  void run(List<String> args) {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    super.run(args);
  }

  @override
  Widget get app =>
      AppStartListener<AppState>(child: TranslationProvider(child: MyApp()));

  @override
  void onLoaded(BuildContext context, WidgetRef ref, int cost, state) {
    Log.i("App启动成功, 耗时: $cost ms", tag: "START");
    // Restore appearance prefs while Splash is still visible so themeMode
    // applies before MainRoute navigation.
    unawaited(
      ref.read(appPreferencesProvider.notifier).restore().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        Log.e(
          'App偏好提前恢复失败: $error',
          tag: 'START',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  @override
  void onStartError(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace trace,
  ) {
    // Avoid a stuck native splash if theme seeding failed before remove().
    FlutterNativeSplash.remove();
    Log.e('App启动失败: $error', tag: 'START', error: error, stackTrace: trace);
  }

  @override
  void onGlobalError(Object error, StackTrace stack) {
    Log.e('全局错误: $error', tag: 'START', error: error, stackTrace: stack);
  }

  @override
  void onStartSuccess(BuildContext context, WidgetRef ref, state) {
    Log.i("App启动成功", tag: "START");
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      try {
        await ref.read(agentToolConfigsProvider.notifier).restore();
        await ref.read(mcpSessionManagerProvider.notifier).syncEnabledServers();
        await initUser(ref);
      } catch (error, stackTrace) {
        Log.e(
          'App启动后恢复失败: $error',
          tag: 'START',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }

  @override
  AppStartRepository<AppState> get repository => AppStartRepo();

  @override
  List<ProviderObserver>? get observers => null;

  @override
  List<Override>? get overrides => null;

  @override
  Duration? Function(int p1, Object p2)? get retry => null;

  Future<void> initUser(WidgetRef ref) async {
    Log.i("initUser");
  }
}

/// SoulCast 根应用，绑定路由、主题、本地化与全局 SmartDialog。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppBootAppearance.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          routerConfig: appRouter,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          title: t.appName,
          builder: FlutterSmartDialog.init(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
