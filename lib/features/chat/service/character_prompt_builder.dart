import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/shared/prompt/prompt.dart';

/// 将角色卡渲染为角色会话的系统提示词（扮演规则 + 静态人设）。
///
/// 该内容始终从 [CharacterEntity] 实时读取，不写入会话记忆，也不被记忆整理器修改。
Future<String> buildCharacterSystemPrompt(
  CharacterEntity character, {
  required String template,
  String? fallbackTemplate,
}) {
  return renderPromptTemplate(template, {
    PromptTokenNames.name: character.name.trim(),
    PromptTokenNames.description: character.description.trim(),
    PromptTokenNames.personality: character.personality.trim(),
    PromptTokenNames.speechStyle: character.speechStyle.trim(),
    PromptTokenNames.appearance: character.appearance.trim(),
    PromptTokenNames.scenario: character.scenario.trim(),
    PromptTokenNames.exampleDialogues: character.exampleDialogues.trim(),
    PromptTokenNames.hardConstraints: character.hardConstraints.trim(),
  }, fallbackTemplate: fallbackTemplate);
}
