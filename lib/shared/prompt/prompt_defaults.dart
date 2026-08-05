import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/prompt/prompt_id.dart';
import 'package:soulcast/shared/prompt/prompt_template_resolver.dart';

/// 合并自定义偏好与 i18n 默认，得到有效模板。
String effectivePromptTemplate({
  required PromptId id,
  required Map<String, String> customPrompts,
  required Translations t,
}) {
  return resolvePromptTemplate(
    custom: customPromptOf(customPrompts, id),
    defaultTemplate: defaultPromptTemplate(t, id),
  );
}

/// 从 i18n 读取指定提示词的默认模板全文。
String defaultPromptTemplate(Translations t, PromptId id) {
  final defaults = t.prompts.defaults;
  return switch (id) {
    PromptId.appSystem => defaults.appSystem,
    PromptId.characterRolePlay => defaults.characterRolePlay,
    PromptId.memoryInjectNormal => defaults.memoryInjectNormal,
    PromptId.memoryInjectRolePlay => defaults.memoryInjectRolePlay,
    PromptId.memoryUpdateSystem => defaults.memoryUpdateSystem,
    PromptId.memoryUpdateUserNormal => defaults.memoryUpdateUserNormal,
    PromptId.memoryUpdateUserRolePlay => defaults.memoryUpdateUserRolePlay,
    PromptId.titleSystem => defaults.titleSystem,
    PromptId.titleUser => defaults.titleUser,
    PromptId.generateCharacterSystem => defaults.generateCharacterSystem,
    PromptId.generateCharacterUser => defaults.generateCharacterUser,
    PromptId.avatarImageWrap => defaults.avatarImageWrap,
  };
}

/// 列表项标题。
String promptListTitle(Translations t, PromptId id) {
  final items = t.prompts.items;
  return switch (id) {
    PromptId.appSystem => items.appSystem.title,
    PromptId.characterRolePlay => items.characterRolePlay.title,
    PromptId.memoryInjectNormal => items.memoryInjectNormal.title,
    PromptId.memoryInjectRolePlay => items.memoryInjectRolePlay.title,
    PromptId.memoryUpdateSystem => items.memoryUpdateSystem.title,
    PromptId.memoryUpdateUserNormal => items.memoryUpdateUserNormal.title,
    PromptId.memoryUpdateUserRolePlay => items.memoryUpdateUserRolePlay.title,
    PromptId.titleSystem => items.titleSystem.title,
    PromptId.titleUser => items.titleUser.title,
    PromptId.generateCharacterSystem => items.generateCharacterSystem.title,
    PromptId.generateCharacterUser => items.generateCharacterUser.title,
    PromptId.avatarImageWrap => items.avatarImageWrap.title,
  };
}

/// 列表项副标题。
String promptListSubtitle(Translations t, PromptId id) {
  final items = t.prompts.items;
  return switch (id) {
    PromptId.appSystem => items.appSystem.subtitle,
    PromptId.characterRolePlay => items.characterRolePlay.subtitle,
    PromptId.memoryInjectNormal => items.memoryInjectNormal.subtitle,
    PromptId.memoryInjectRolePlay => items.memoryInjectRolePlay.subtitle,
    PromptId.memoryUpdateSystem => items.memoryUpdateSystem.subtitle,
    PromptId.memoryUpdateUserNormal => items.memoryUpdateUserNormal.subtitle,
    PromptId.memoryUpdateUserRolePlay =>
      items.memoryUpdateUserRolePlay.subtitle,
    PromptId.titleSystem => items.titleSystem.subtitle,
    PromptId.titleUser => items.titleUser.subtitle,
    PromptId.generateCharacterSystem => items.generateCharacterSystem.subtitle,
    PromptId.generateCharacterUser => items.generateCharacterUser.subtitle,
    PromptId.avatarImageWrap => items.avatarImageWrap.subtitle,
  };
}

/// Token 说明文案；未知 token 回退为名称本身。
String promptTokenDescription(Translations t, String tokenName) {
  final tokens = t.prompts.tokens;
  return switch (tokenName) {
    'user' => tokens.user,
    'name' => tokens.name,
    'personality' => tokens.personality,
    'speechStyle' => tokens.speechStyle,
    'appearance' => tokens.appearance,
    'scenario' => tokens.scenario,
    'exampleDialogues' => tokens.exampleDialogues,
    'hardConstraints' => tokens.hardConstraints,
    'summary' => tokens.summary,
    'facts' => tokens.facts,
    'factsJson' => tokens.factsJson,
    'userMessage' => tokens.userMessage,
    'assistantMessage' => tokens.assistantMessage,
    'userText' => tokens.userText,
    'assistantText' => tokens.assistantText,
    'idea' => tokens.idea,
    'userPrompt' => tokens.userPrompt,
    _ => tokenName,
  };
}
