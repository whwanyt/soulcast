/// 应用路由路径常量与动态路径构造器。
class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const main = '/main';
  static const chatInfo = '/chat-info/:conversationId';
  static const characterManagement = '/character-management';
  static const characterEdit = '/character-management/edit';
  static const characterWorldBooks = '/character-management/world-books';
  static const fileLibrary = '/file-library';
  static const settings = '/settings';
  static const providerSettings = '/settings/providers';
  static const providerDetail = '/settings/providers/detail';
  static const prompts = '/settings/prompts';
  static const promptEdit = '/settings/prompts/:promptId';
  static const modelSettings = '/settings/model';
  static const messageDisplaySettings = '/settings/message-display';
  static const agentToolSettings = '/settings/agent-tools';
  static const mcpSettings = '/settings/mcp';
  static const mcpServerEdit = '/settings/mcp/edit';
  static const speechModels = '/settings/speech-models';
  static const speechOutput = '/settings/speech-output';
  static const worldBookSettings = '/settings/world-books';
  static const worldBookEdit = '/settings/world-books/edit';
  static const worldBookEntryEdit = '/settings/world-books/entry';
  static const language = '/settings/language';
  static const storage = '/settings/storage';
  static const storageCategory = '/settings/storage/:category';
  static const about = '/settings/about';
  static const debug = '/settings/debug';

  /// 构造指定会话的信息页路径，并对路径参数进行编码。
  static String chatInfoLocation(String conversationId) {
    return '/chat-info/${Uri.encodeComponent(conversationId)}';
  }
}
