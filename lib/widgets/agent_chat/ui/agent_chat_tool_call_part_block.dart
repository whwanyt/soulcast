import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';

import 'agent_chat_message_shared.dart';

/// 可展开查看参数与结果的工具调用状态块。
class AgentChatToolCallPartBlock extends StatefulWidget {
  const AgentChatToolCallPartBlock({super.key, required this.part});

  final ChatToolCallPart part;

  @override
  State<AgentChatToolCallPartBlock> createState() =>
      _AgentChatToolCallPartBlockState();
}

class _AgentChatToolCallPartBlockState
    extends State<AgentChatToolCallPartBlock> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final translations = context.t;
    final part = widget.part;
    final isRunning = part.status == ChatToolCallPartStatus.running;
    final statusLabel = switch (part.status) {
      ChatToolCallPartStatus.running => translations.chat.toolCall.running,
      ChatToolCallPartStatus.completed => translations.chat.toolCall.completed,
      ChatToolCallPartStatus.failed => translations.chat.toolCall.failed,
    };
    final title =
        '${translations.chat.role.tool}: ${part.toolName} · $statusLabel';
    final detailStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontFamily: 'monospace',
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentChatMessageCollapsibleHeader(
          icon: isRunning ? LucideIcons.loaderCircle : LucideIcons.wrench,
          title: title,
          color: colorScheme.onSurfaceVariant,
          isExpanded: _isExpanded,
          onTap: _toggleExpanded,
          trailing: isRunning
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          if (part.arguments != null && part.arguments!.trim().isNotEmpty) ...[
            Text(
              translations.chat.toolCall.arguments,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(part.arguments!, style: detailStyle),
            const SizedBox(height: 8),
          ],
          if (part.result != null && part.result!.trim().isNotEmpty) ...[
            Text(
              translations.chat.toolCall.result,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(part.result!, style: detailStyle),
          ],
        ],
      ],
    );
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }
}
