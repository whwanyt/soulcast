import '../model/chat_conversation_title_origin.dart';

const defaultChatConversationTitle = '新会话';

const chatConversationTitleMaxLength = 24;

/// 判断标题是否仍为默认占位名称。
bool isDefaultChatConversationTitle(String title) {
  return title.trim() == defaultChatConversationTitle;
}

/// 判断当前标题来源是否允许自动生成标题。
bool canAutoGenerateChatConversationTitle(
  ChatConversationTitleOrigin titleOrigin,
) {
  return titleOrigin == ChatConversationTitleOrigin.pending;
}

/// 规范化会话标题，并为空标题提供默认名称、为长标题截断。
String resolveChatConversationTitle(String? title) {
  final normalized = title?.trim();
  if (normalized == null || normalized.isEmpty) {
    return defaultChatConversationTitle;
  }
  return normalized.length <= chatConversationTitleMaxLength
      ? normalized
      : '${normalized.substring(0, chatConversationTitleMaxLength)}...';
}

/// 清洗 LLM 返回的会话标题；无效时返回 `null`。
String? sanitizeGeneratedChatConversationTitle(String? raw) {
  if (raw == null) {
    return null;
  }

  var text = raw.trim();
  if (text.isEmpty) {
    return null;
  }

  final newlineIndex = text.indexOf('\n');
  if (newlineIndex >= 0) {
    text = text.substring(0, newlineIndex).trim();
  }
  text = _stripWrappingQuotes(text);
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty || isDefaultChatConversationTitle(text)) {
    return null;
  }

  final resolved = resolveChatConversationTitle(text);
  if (isDefaultChatConversationTitle(resolved)) {
    return null;
  }
  return resolved;
}

String _stripWrappingQuotes(String value) {
  if (value.length < 2) {
    return value;
  }

  final pairs = <String, String>{
    '"': '"',
    "'": "'",
    '“': '”',
    '‘': '’',
    '「': '」',
    '『': '』',
  };
  final end = pairs[value[0]];
  if (end != null && value.endsWith(end)) {
    return value.substring(1, value.length - 1).trim();
  }
  return value;
}
