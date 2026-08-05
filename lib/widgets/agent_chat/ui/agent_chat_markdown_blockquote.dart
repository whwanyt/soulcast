part of 'agent_chat_markdown.dart';

/// 压缩引用块内部多余换行的 Markdown 内联规则。
class _AgentChatTightNewLines extends InlineMd {
  @override
  RegExp get exp => RegExp(r'\n\n+');

  @override
  InlineSpan span(BuildContext context, String text, GptMarkdownConfig config) {
    final styles = AgentChatMarkdownStyles.resolve(
      colorScheme: Theme.of(context).colorScheme,
      base: config.style ?? const TextStyle(),
    );
    return TextSpan(text: '\n\n', style: styles.paragraphGap(config.style));
  }
}

/// 聊天样式的 Markdown 引用块规则。
class _AgentChatBlockQuoteMd extends InlineMd {
  @override
  bool get inline => false;

  @override
  RegExp get exp => RegExp(
    r'(?:(?:^)\ *>[^\n]+)(?:(?:\n)\ *>[^\n]+)*',
    dotAll: true,
    multiLine: true,
  );

  @override
  InlineSpan span(BuildContext context, String text, GptMarkdownConfig config) {
    final match = exp.firstMatch(text);
    final dataBuilder = StringBuffer();
    final matched = match?[0] ?? '';
    for (final each in matched.split('\n')) {
      if (each.startsWith(RegExp(r'\ *>'))) {
        var subString = each.trimLeft().substring(1);
        if (subString.startsWith(' ')) {
          subString = subString.substring(1);
        }
        dataBuilder.writeln(subString);
      } else {
        dataBuilder.writeln(each);
      }
    }
    final data = dataBuilder.toString().trim();
    final child = TextSpan(
      children: MarkdownComponent.generate(context, data, config, true),
    );
    final styles = AgentChatMarkdownStyles.resolve(
      colorScheme: Theme.of(context).colorScheme,
      base: config.style ?? const TextStyle(),
    );
    final chrome = styles.chrome;
    final labelColor = styles.colorScheme.onSurfaceVariant;

    return TextSpan(
      children: [
        WidgetSpan(
          child: Directionality(
            textDirection: config.textDirection,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: ClipRRect(
                borderRadius: chrome.radius,
                child: DecoratedBox(
                  decoration: chrome.panel(),
                  child: Stack(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ColoredBox(
                              color: chrome.accent,
                              child: const SizedBox(width: 3),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.sm,
                                  AppSpacing.xs,
                                  36,
                                  AppSpacing.xs,
                                ),
                                child: DefaultTextStyle.merge(
                                  style: styles.quote(config.style),
                                  child: config.getRich(child),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: AgentChatCopyIconButton(
                          text: data,
                          color: labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
