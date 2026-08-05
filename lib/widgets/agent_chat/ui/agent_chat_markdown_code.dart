part of 'agent_chat_markdown.dart';

/// 带语法高亮与统一边框的 Markdown 代码块。
class _AgentChatMarkdownCodeBlock extends StatelessWidget {
  const _AgentChatMarkdownCodeBlock({
    required this.name,
    required this.code,
    required this.styles,
  });

  final String name;
  final String code;
  final AgentChatMarkdownStyles styles;

  @override
  Widget build(BuildContext context) {
    final label = name.trim();
    final chrome = styles.chrome;
    final highlighted = SyntaxHighlighterService.highlight(
      code: code,
      language: label,
      brightness: Theme.of(context).brightness,
    );
    final labelColor = styles.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ClipRRect(
        borderRadius: chrome.radius,
        child: DecoratedBox(
          decoration: chrome.panel(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: chrome.header,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: label.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: styles.codeLabel(),
                              ),
                      ),
                      AgentChatCopyIconButton(text: code, color: labelColor),
                    ],
                  ),
                ),
              ),
              ColoredBox(
                color: chrome.divider,
                child: const SizedBox(height: 1),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text.rich(highlighted, style: styles.code),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
