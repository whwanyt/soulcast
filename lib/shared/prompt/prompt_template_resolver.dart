import 'dart:convert';

import 'prompt_id.dart';

/// 解析有效提示词模板：自定义非空时用自定义，否则用默认。
String resolvePromptTemplate({
  required String? custom,
  required String defaultTemplate,
}) {
  final trimmedCustom = custom?.trim();
  if (trimmedCustom != null && trimmedCustom.isNotEmpty) {
    return trimmedCustom;
  }
  return defaultTemplate;
}

/// 将自定义提示词 Map 编码为偏好存储 JSON。
String? encodeCustomPrompts(Map<String, String> prompts) {
  if (prompts.isEmpty) {
    return null;
  }
  final normalized = <String, String>{};
  for (final entry in prompts.entries) {
    final key = entry.key.trim();
    final value = entry.value.trim();
    if (key.isEmpty || value.isEmpty) {
      continue;
    }
    normalized[key] = value;
  }
  if (normalized.isEmpty) {
    return null;
  }
  return jsonEncode(normalized);
}

/// 解码偏好中的自定义提示词 Map；非法 JSON 视为空。
Map<String, String> decodeCustomPrompts(String? json) {
  final trimmed = json?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return const {};
  }
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is! Map) {
      return const {};
    }
    final result = <String, String>{};
    for (final entry in decoded.entries) {
      final value = entry.value?.toString().trim();
      if (value == null || value.isEmpty) {
        continue;
      }
      result[entry.key.toString()] = value;
    }
    return result;
  } catch (_) {
    return const {};
  }
}

String? customPromptOf(Map<String, String> prompts, PromptId id) {
  final value = prompts[id.storageKey]?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

Map<String, String> upsertCustomPrompt(
  Map<String, String> current,
  PromptId id,
  String? value,
) {
  final next = Map<String, String>.from(current);
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    next.remove(id.storageKey);
  } else {
    next[id.storageKey] = normalized;
  }
  return next;
}
