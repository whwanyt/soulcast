import 'package:soulcast/shared/prompt/prompt.dart';

/// 角色卡 JSON 生成器的系统提示。
Future<String> buildGenerateCharacterSystemPrompt({
  required String template,
  String? fallbackTemplate,
}) {
  return renderPromptTemplate(
    template,
    const {},
    fallbackTemplate: fallbackTemplate,
  );
}

/// 根据用户创意构造角色卡生成提示。
Future<String> buildGenerateCharacterUserPrompt(
  String idea, {
  required String template,
  String? fallbackTemplate,
}) {
  return renderPromptTemplate(template, {
    PromptTokenNames.idea: idea.trim(),
  }, fallbackTemplate: fallbackTemplate);
}

/// 头像生成 sheet 的默认提示词：仅使用外貌与形象。
String buildDefaultAvatarPromptText({required String appearance}) {
  return appearance.trim();
}

/// 将用户编辑后的提示词包装为头像向图像提示。
Future<String> buildCharacterAvatarImagePrompt(
  String userPrompt, {
  required String template,
  String? fallbackTemplate,
}) {
  return renderPromptTemplate(template, {
    PromptTokenNames.userPrompt: userPrompt.trim(),
  }, fallbackTemplate: fallbackTemplate);
}
