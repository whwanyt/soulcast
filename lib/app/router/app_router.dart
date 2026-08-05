import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soulcast/pages/about/about_page.dart';
import 'package:soulcast/pages/agent_tool_settings/agent_tool_settings_page.dart';
import 'package:soulcast/pages/chat_info/chat_info_page.dart';
import 'package:soulcast/pages/debug/debug_page.dart';
import 'package:soulcast/pages/character_edit/character_edit_page.dart';
import 'package:soulcast/pages/character_management/character_management_page.dart';
import 'package:soulcast/pages/character_world_books/character_world_books_page.dart';
import 'package:soulcast/pages/file_library/file_library_page.dart';
import 'package:soulcast/pages/language/language_page.dart';
import 'package:soulcast/pages/main/main_page.dart';
import 'package:soulcast/pages/mcp_settings/mcp_server_edit_page.dart';
import 'package:soulcast/pages/mcp_settings/mcp_settings_page.dart';
import 'package:soulcast/pages/message_display_settings/message_display_settings_page.dart';
import 'package:soulcast/pages/provider_detail/provider_detail_page.dart';
import 'package:soulcast/pages/model_settings/model_settings_page.dart';
import 'package:soulcast/pages/prompts/prompt_edit_page.dart';
import 'package:soulcast/pages/prompts/prompts_list_page.dart';
import 'package:soulcast/pages/provider_settings/provider_settings_page.dart';
import 'package:soulcast/pages/settings/settings_page.dart';
import 'package:soulcast/pages/speech_model_settings/speech_model_settings_page.dart';
import 'package:soulcast/pages/speech_output_settings/speech_output_settings_page.dart';
import 'package:soulcast/pages/splash/splash_page.dart';
import 'package:soulcast/pages/storage/storage_category_page.dart';
import 'package:soulcast/pages/storage/storage_page.dart';
import 'package:soulcast/pages/world_book_edit/world_book_edit_page.dart';
import 'package:soulcast/pages/world_book_entry_edit/world_book_entry_edit_page.dart';
import 'package:soulcast/pages/world_book_settings/world_book_settings_page.dart';
import 'package:soulcast/shared/navigation/app_routes.dart';

part 'app_router.g.dart';

/// 根导航器 key，供应用级弹窗和导航能力定位主 Navigator。
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// 应用 typed route 路由器。
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: $appRoutes,
);

@TypedGoRoute<SplashRoute>(path: AppRoutes.splash)
/// 启动页 typed route。
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashPage();
}

@TypedGoRoute<MainRoute>(path: AppRoutes.main)
/// 主聊天页 typed route。
class MainRoute extends GoRouteData with $MainRoute {
  const MainRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MainPage();
}

@TypedGoRoute<ChatInfoRoute>(path: AppRoutes.chatInfo)
/// 会话详情页 typed route。
class ChatInfoRoute extends GoRouteData with $ChatInfoRoute {
  const ChatInfoRoute({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ChatInfoPage(conversationId: conversationId);
}

@TypedGoRoute<CharacterManagementRoute>(path: AppRoutes.characterManagement)
/// 角色管理页 typed route。
class CharacterManagementRoute extends GoRouteData
    with $CharacterManagementRoute {
  const CharacterManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CharacterManagementPage();
}

@TypedGoRoute<FileLibraryRoute>(path: AppRoutes.fileLibrary)
/// 文件库页 typed route。
class FileLibraryRoute extends GoRouteData with $FileLibraryRoute {
  const FileLibraryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const FileLibraryPage();
}

@TypedGoRoute<CharacterEditRoute>(path: AppRoutes.characterEdit)
/// 角色编辑页 typed route。
class CharacterEditRoute extends GoRouteData with $CharacterEditRoute {
  const CharacterEditRoute({this.characterId});

  final String? characterId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CharacterEditPage(characterId: characterId);
}

@TypedGoRoute<CharacterWorldBooksRoute>(path: AppRoutes.characterWorldBooks)
/// 角色世界书绑定页 typed route。
class CharacterWorldBooksRoute extends GoRouteData
    with $CharacterWorldBooksRoute {
  const CharacterWorldBooksRoute({required this.characterId});

  final String characterId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CharacterWorldBooksPage(characterId: characterId);
}

@TypedGoRoute<SettingsRoute>(path: AppRoutes.settings)
/// 设置页 typed route。
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}

@TypedGoRoute<ProviderSettingsRoute>(path: AppRoutes.providerSettings)
/// AI 服务商设置页 typed route。
class ProviderSettingsRoute extends GoRouteData with $ProviderSettingsRoute {
  const ProviderSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProviderSettingsPage();
}

@TypedGoRoute<ProviderDetailRoute>(path: AppRoutes.providerDetail)
/// AI 服务商详情页 typed route。
class ProviderDetailRoute extends GoRouteData with $ProviderDetailRoute {
  const ProviderDetailRoute({this.providerId});

  final String? providerId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProviderDetailPage(providerId: providerId);
}

@TypedGoRoute<PromptsRoute>(
  path: AppRoutes.prompts,
  routes: [TypedGoRoute<PromptEditRoute>(path: ':promptId')],
)
/// 提示词列表 typed route。
class PromptsRoute extends GoRouteData with $PromptsRoute {
  const PromptsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PromptsListPage();
}

/// 提示词编辑 typed route。
class PromptEditRoute extends GoRouteData with $PromptEditRoute {
  const PromptEditRoute({required this.promptId});

  final String promptId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PromptEditPage(promptId: promptId);
}

@TypedGoRoute<ModelSettingsRoute>(path: AppRoutes.modelSettings)
/// 模型设置 typed route。
class ModelSettingsRoute extends GoRouteData with $ModelSettingsRoute {
  const ModelSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ModelSettingsPage();
}

@TypedGoRoute<MessageDisplaySettingsRoute>(
  path: AppRoutes.messageDisplaySettings,
)
/// 消息显示设置页 typed route。
class MessageDisplaySettingsRoute extends GoRouteData
    with $MessageDisplaySettingsRoute {
  const MessageDisplaySettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MessageDisplaySettingsPage();
}

@TypedGoRoute<AgentToolSettingsRoute>(path: AppRoutes.agentToolSettings)
/// Agent 工具设置页 typed route。
class AgentToolSettingsRoute extends GoRouteData with $AgentToolSettingsRoute {
  const AgentToolSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AgentToolSettingsPage();
}

@TypedGoRoute<McpSettingsRoute>(path: AppRoutes.mcpSettings)
/// MCP Server 设置页 typed route。
class McpSettingsRoute extends GoRouteData with $McpSettingsRoute {
  const McpSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const McpSettingsPage();
}

@TypedGoRoute<McpServerEditRoute>(path: AppRoutes.mcpServerEdit)
/// MCP Server 编辑页 typed route。
class McpServerEditRoute extends GoRouteData with $McpServerEditRoute {
  const McpServerEditRoute({this.serverId});

  final String? serverId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      McpServerEditPage(serverId: serverId);
}

@TypedGoRoute<SpeechModelSettingsRoute>(path: AppRoutes.speechModels)
/// 语音模型设置页 typed route。
class SpeechModelSettingsRoute extends GoRouteData
    with $SpeechModelSettingsRoute {
  const SpeechModelSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SpeechModelSettingsPage();
}

@TypedGoRoute<SpeechOutputSettingsRoute>(path: AppRoutes.speechOutput)
/// 语音输出设置页 typed route。
class SpeechOutputSettingsRoute extends GoRouteData
    with $SpeechOutputSettingsRoute {
  const SpeechOutputSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SpeechOutputSettingsPage();
}

@TypedGoRoute<WorldBookSettingsRoute>(path: AppRoutes.worldBookSettings)
/// 世界书资源库列表 typed route。
class WorldBookSettingsRoute extends GoRouteData with $WorldBookSettingsRoute {
  const WorldBookSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const WorldBookSettingsPage();
}

@TypedGoRoute<WorldBookEditRoute>(path: AppRoutes.worldBookEdit)
/// 世界书编辑 typed route。
class WorldBookEditRoute extends GoRouteData with $WorldBookEditRoute {
  const WorldBookEditRoute({this.worldBookId});

  final String? worldBookId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorldBookEditPage(worldBookId: worldBookId);
}

@TypedGoRoute<WorldBookEntryEditRoute>(path: AppRoutes.worldBookEntryEdit)
/// 世界书条目编辑 typed route。
class WorldBookEntryEditRoute extends GoRouteData
    with $WorldBookEntryEditRoute {
  const WorldBookEntryEditRoute({required this.worldBookId, this.entryId});

  final String worldBookId;
  final String? entryId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorldBookEntryEditPage(worldBookId: worldBookId, entryId: entryId);
}

@TypedGoRoute<LanguageRoute>(path: AppRoutes.language)
/// 语言设置页 typed route。
class LanguageRoute extends GoRouteData with $LanguageRoute {
  const LanguageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LanguagePage();
}

@TypedGoRoute<StorageRoute>(
  path: AppRoutes.storage,
  routes: [TypedGoRoute<StorageCategoryRoute>(path: ':category')],
)
/// 存储管理页及分类子路由的 typed route。
class StorageRoute extends GoRouteData with $StorageRoute {
  const StorageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const StoragePage();
}

/// 存储分类详情页 typed route。
class StorageCategoryRoute extends GoRouteData with $StorageCategoryRoute {
  const StorageCategoryRoute({required this.category});

  final String category;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      StorageCategoryPage(category: category);
}

@TypedGoRoute<AboutRoute>(path: AppRoutes.about)
/// 关于我们页 typed route。
class AboutRoute extends GoRouteData with $AboutRoute {
  const AboutRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const AboutPage();
}

@TypedGoRoute<DebugRoute>(path: AppRoutes.debug)
/// 调试页 typed route。
class DebugRoute extends GoRouteData with $DebugRoute {
  const DebugRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const DebugPage();
}
