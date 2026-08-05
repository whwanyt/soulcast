part of '../chat_info_page.dart';

/// 会话摘要、系统提示词与清理动作的基础配置页签。
class _BasicConfigTab extends StatelessWidget {
  const _BasicConfigTab({
    required this.summary,
    required this.conversationSystemPrompt,
    required this.appSystemPrompt,
    required this.worldBooksSummary,
    required this.isEnabled,
    required this.onSummaryEdited,
    required this.onSystemPromptEdited,
    required this.onWorldBooksEdited,
    required this.onConversationClear,
  });

  final String summary;
  final String? conversationSystemPrompt;
  final String appSystemPrompt;
  final String worldBooksSummary;
  final bool isEnabled;
  final VoidCallback onSummaryEdited;
  final VoidCallback onSystemPromptEdited;
  final VoidCallback onWorldBooksEdited;
  final VoidCallback onConversationClear;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.main.info;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _ConfigListItem(
          icon: LucideIcons.fileText,
          title: translations.summaryLabel,
          value: summary.trim().isEmpty
              ? translations.emptySummary
              : summary.trim(),
          isEnabled: isEnabled,
          onTap: onSummaryEdited,
        ),
        const SizedBox(height: 10),
        _ConfigListItem(
          icon: LucideIcons.messageSquareText,
          title: translations.systemPromptLabel,
          subtitle: conversationSystemPrompt == null
              ? translations.usingAppSystemPrompt
              : translations.usingConversationSystemPrompt,
          value: (conversationSystemPrompt ?? appSystemPrompt).trim(),
          isEnabled: isEnabled,
          onTap: onSystemPromptEdited,
        ),
        const SizedBox(height: 10),
        _ConfigListItem(
          icon: LucideIcons.bookOpen,
          title: translations.worldBooksLabel,
          value: worldBooksSummary,
          isEnabled: isEnabled,
          onTap: onWorldBooksEdited,
        ),
        const SizedBox(height: 10),
        _ConfigListItem(
          icon: LucideIcons.trash2,
          title: translations.clearConversation,
          value: translations.clearConversationDescription,
          isEnabled: isEnabled,
          isDestructive: true,
          onTap: onConversationClear,
        ),
      ],
    );
  }
}

class _ConfigListItem extends StatelessWidget {
  const _ConfigListItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.isEnabled,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String value;
  final bool isEnabled;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;
    final titleColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;
    final bodyColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      value,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: bodyColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 18, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
