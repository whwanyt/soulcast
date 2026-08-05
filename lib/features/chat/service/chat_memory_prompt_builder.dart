import 'dart:convert';

import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/shared/prompt/prompt.dart';

const chatMemorySummaryMaxLength = 1200;
const chatMemoryFactsMaxCount = 24;
const chatMemoryFactMaxLength = 220;

/// 将长期记忆转换为注入聊天请求的系统提示词。
Future<String?> buildChatMemorySystemPrompt(
  ChatConversationMemory memory, {
  required String template,
  String? fallbackTemplate,
}) async {
  final summary = _limitText(memory.summary.trim(), chatMemorySummaryMaxLength);
  final factLines = memory.facts
      .where((fact) => fact.content.trim().isNotEmpty)
      .take(chatMemoryFactsMaxCount)
      .map(
        (fact) =>
            '- ${fact.category.name}: ${_limitText(fact.content.trim(), chatMemoryFactMaxLength)}',
      )
      .toList();

  if (summary.isEmpty && factLines.isEmpty) {
    return null;
  }

  final rendered = await renderPromptTemplate(template, {
    PromptTokenNames.summary: summary,
    PromptTokenNames.facts: factLines.join('\n'),
  }, fallbackTemplate: fallbackTemplate);
  final trimmed = rendered.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// 构造让模型基于最新一轮对话整理长期记忆的 JSON 指令。
Future<String> buildChatMemoryUpdatePrompt({
  required ChatConversationMemory memory,
  required ChatConversationMessage userMessage,
  required ChatConversationMessage assistantMessage,
  required String template,
  String? fallbackTemplate,
}) {
  final summary = memory.summary.trim().isEmpty ? '无' : memory.summary.trim();
  final facts = memory.facts
      .where((fact) => fact.content.trim().isNotEmpty)
      .map(
        (fact) => {
          'id': fact.id,
          'category': fact.category.name,
          'content': fact.content,
          'createdAt': fact.createdAt.toIso8601String(),
          'updatedAt': fact.updatedAt.toIso8601String(),
        },
      )
      .toList();

  return renderPromptTemplate(template, {
    PromptTokenNames.summary: summary,
    PromptTokenNames.factsJson: jsonEncode(facts),
    PromptTokenNames.userMessage: userMessage.content,
    PromptTokenNames.assistantMessage: assistantMessage.content,
  }, fallbackTemplate: fallbackTemplate);
}

String _limitText(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength)}...';
}
