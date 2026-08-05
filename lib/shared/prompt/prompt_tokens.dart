import 'prompt_id.dart';

/// 提示词模板中声明的约定变量名（不含 `{{` / `}}`）。
abstract final class PromptTokenNames {
  static const user = 'user';
  static const name = 'name';
  static const description = 'description';
  static const personality = 'personality';
  static const speechStyle = 'speechStyle';
  static const appearance = 'appearance';
  static const scenario = 'scenario';
  static const exampleDialogues = 'exampleDialogues';
  static const hardConstraints = 'hardConstraints';
  static const summary = 'summary';
  static const facts = 'facts';
  static const factsJson = 'factsJson';
  static const userMessage = 'userMessage';
  static const assistantMessage = 'assistantMessage';
  static const userText = 'userText';
  static const assistantText = 'assistantText';
  static const idea = 'idea';
  static const userPrompt = 'userPrompt';
}

/// 返回指定提示词支持的 token 名称列表（编辑页列举用）。
List<String> supportedTokensFor(PromptId id) {
  const common = [PromptTokenNames.user];
  final specific = switch (id) {
    PromptId.appSystem ||
    PromptId.memoryUpdateSystem ||
    PromptId.titleSystem ||
    PromptId.generateCharacterSystem => const <String>[],
    PromptId.characterRolePlay => const [
      PromptTokenNames.name,
      PromptTokenNames.description,
      PromptTokenNames.personality,
      PromptTokenNames.speechStyle,
      PromptTokenNames.appearance,
      PromptTokenNames.scenario,
      PromptTokenNames.exampleDialogues,
      PromptTokenNames.hardConstraints,
    ],
    PromptId.memoryInjectNormal || PromptId.memoryInjectRolePlay => const [
      PromptTokenNames.summary,
      PromptTokenNames.facts,
    ],
    PromptId.memoryUpdateUserNormal ||
    PromptId.memoryUpdateUserRolePlay => const [
      PromptTokenNames.summary,
      PromptTokenNames.factsJson,
      PromptTokenNames.userMessage,
      PromptTokenNames.assistantMessage,
    ],
    PromptId.titleUser => const [
      PromptTokenNames.userText,
      PromptTokenNames.assistantText,
    ],
    PromptId.generateCharacterUser => const [PromptTokenNames.idea],
    PromptId.avatarImageWrap => const [PromptTokenNames.userPrompt],
  };
  return [...common, ...specific];
}

/// 将 token 名称格式化为模板插入文本。
String formatPromptToken(String tokenName) => '{{$tokenName}}';
