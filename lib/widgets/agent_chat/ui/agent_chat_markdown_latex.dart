part of 'agent_chat_markdown.dart';

/// 多行公式块：在默认渲染外包一层 chrome，并支持复制 LaTeX 源码。
class _AgentChatLatexMathMultiLine extends LatexMathMultiLine {
  @override
  Widget build(BuildContext context, String text, GptMarkdownConfig config) {
    final match = exp.firstMatch(text.trim());
    final mathText = match?[1] ?? match?[2] ?? '';
    final child = super.build(context, text, config);
    final styles = AgentChatMarkdownStyles.resolve(
      colorScheme: Theme.of(context).colorScheme,
      base: config.style ?? DefaultTextStyle.of(context).style,
    );

    return _AgentChatMarkdownLatexBlock(
      tex: mathText,
      styles: styles,
      child: child,
    );
  }
}

class _AgentChatMarkdownLatexBlock extends StatelessWidget {
  const _AgentChatMarkdownLatexBlock({
    required this.tex,
    required this.styles,
    required this.child,
  });

  final String tex;
  final AgentChatMarkdownStyles styles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final chrome = styles.chrome;
    final labelColor = styles.colorScheme.onSurfaceVariant;
    final copyText = tex.trim().isEmpty ? '' : '\\[${tex.trim()}\\]';

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
                        child: Text(
                          'LaTeX',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: styles.codeLabel(),
                        ),
                      ),
                      AgentChatCopyIconButton(
                        text: copyText,
                        color: labelColor,
                      ),
                    ],
                  ),
                ),
              ),
              ColoredBox(
                color: chrome.divider,
                child: const SizedBox(height: 1),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
