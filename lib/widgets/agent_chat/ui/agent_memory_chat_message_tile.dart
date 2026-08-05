import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';

import 'agent_chat_message_shared.dart';

/// 将结构化长期记忆更新展示为可折叠消息气泡。
class AgentMemoryChatMessageTile extends StatefulWidget {
  const AgentMemoryChatMessageTile({super.key, required this.message});

  final ChatConversationMessage message;

  @override
  State<AgentMemoryChatMessageTile> createState() =>
      _AgentMemoryChatMessageTileState();
}

class _AgentMemoryChatMessageTileState
    extends State<AgentMemoryChatMessageTile> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translations = context.t;
    final config = resolveAgentChatMessageConfig(
      context,
      _memoryMessageConfig(theme.colorScheme, translations),
    );
    final body = _memoryMessageBody(translations, widget.message.content);

    return AgentChatMessageBubble(
      isUser: false,
      config: config,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgentChatMessageCollapsibleHeader(
            icon: config.icon,
            title: config.label,
            color: config.labelColor,
            isExpanded: _isExpanded,
            onTap: _toggleExpanded,
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 2),
            Text(body, style: _memoryContentStyle(theme, config)),
          ],
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }
}

AgentChatMessageTileConfig _memoryMessageConfig(
  ColorScheme colorScheme,
  Translations translations,
) {
  return AgentChatMessageTileConfig(
    label: translations.chat.role.memory,
    icon: LucideIcons.brain,
    backgroundColor: agentChatAssistantMessageBackground,
    contentColor: colorScheme.onSurface,
    labelColor: colorScheme.onSurfaceVariant,
  );
}

TextStyle? _memoryContentStyle(
  ThemeData theme,
  AgentChatMessageTileConfig config,
) {
  return theme.textTheme.bodySmall?.copyWith(
    color: config.contentColor,
    height: 1.45,
    letterSpacing: -0.1,
  );
}

String _memoryMessageBody(Translations translations, String content) {
  final decoded = decodeChatMemoryMessageContent(content);
  if (decoded == null) {
    return content;
  }

  final buffer = StringBuffer();
  final summary = decoded.summary.trim();
  if (summary.isNotEmpty) {
    buffer.writeln(translations.chat.memoryMessage.summary);
    buffer.writeln(summary);
  }

  if (decoded.facts.isNotEmpty) {
    buffer.writeln(translations.chat.memoryMessage.memories);
    for (final fact in decoded.facts) {
      final category = ChatMemoryFactCategory.fromName(fact.category);
      buffer.writeln(
        translations.chat.memoryMessage.memoryItem(
          category: _memoryFactCategoryLabel(translations, category),
          content: fact.content,
        ),
      );
    }
  }

  final text = buffer.toString().trimRight();
  return text.isEmpty ? content : text;
}

String _memoryFactCategoryLabel(
  Translations translations,
  ChatMemoryFactCategory category,
) {
  final labels = translations.main.info.category;
  return switch (category) {
    ChatMemoryFactCategory.relationship => labels.relationship,
    ChatMemoryFactCategory.worldSetting => labels.worldSetting,
    ChatMemoryFactCategory.plotState => labels.plotState,
    ChatMemoryFactCategory.preference => labels.preference,
    ChatMemoryFactCategory.constraint => labels.constraint,
    ChatMemoryFactCategory.other => labels.other,
  };
}
