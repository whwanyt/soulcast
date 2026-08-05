import 'package:flute_core/log/log.dart' as flute_log;
import 'package:template_engine/template_engine.dart';

import 'prompt_common_tokens.dart';

final TemplateEngine _promptTemplateEngine = TemplateEngine();

/// 使用 template_engine 渲染提示词模板。
///
/// 渲染前会经 [assemblePromptTokenValues] 自动注入通用 token（如 `{{user}}`）。
/// [fallbackTemplate] 在主模板解析/渲染出错时用于重试；仍失败则返回空串。
Future<String> renderPromptTemplate(
  String template,
  Map<String, Object> values, {
  String? fallbackTemplate,
}) async {
  final assembled = assemblePromptTokenValues(values);
  final primary = await _tryRender(template, assembled);
  if (primary != null) {
    return primary;
  }

  final fallback = fallbackTemplate?.trim();
  if (fallback != null && fallback.isNotEmpty && fallback != template.trim()) {
    final secondary = await _tryRender(fallback, assembled);
    if (secondary != null) {
      return secondary;
    }
  }

  return '';
}

Future<String?> _tryRender(String template, Map<String, Object> values) async {
  try {
    final parseResult = await _promptTemplateEngine.parseText(template);
    final renderResult = await _promptTemplateEngine.render(
      parseResult,
      values,
    );
    if (renderResult.errorMessage.trim().isNotEmpty) {
      flute_log.Log.e(
        'Prompt template render errors: ${renderResult.errorMessage}',
        tag: 'Prompt',
      );
      return null;
    }
    return renderResult.text;
  } catch (error, stackTrace) {
    flute_log.Log.e(
      'Prompt template render failed: $error',
      tag: 'Prompt',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}
