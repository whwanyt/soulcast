part of 'agent_chat_markdown.dart';

/// Markdown 行内代码样式。
class _AgentChatMarkdownInlineCode extends StatelessWidget {
  const _AgentChatMarkdownInlineCode({
    required this.text,
    required this.style,
    required this.chrome,
  });

  final String text;
  final TextStyle style;
  final AgentChatMarkdownChrome chrome;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chrome.header,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: chrome.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Text(
          text,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Markdown 无序列表项布局。
class _AgentChatMarkdownUnorderedItem extends StatelessWidget {
  const _AgentChatMarkdownUnorderedItem({
    required this.config,
    required this.styles,
    required this.child,
  });

  final GptMarkdownConfig config;
  final AgentChatMarkdownStyles styles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fontSize =
        config.style?.fontSize ??
        DefaultTextStyle.of(context).style.fontSize ??
        14;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: UnorderedListView(
        bulletColor: styles.bulletColor,
        padding: 0,
        spacing: 8,
        bulletSize: styles.bulletSize(fontSize),
        textDirection: config.textDirection,
        child: child,
      ),
    );
  }
}

/// Markdown 有序列表项布局。
class _AgentChatMarkdownOrderedItem extends StatelessWidget {
  const _AgentChatMarkdownOrderedItem({
    required this.no,
    required this.config,
    required this.styles,
    required this.child,
  });

  final String no;
  final GptMarkdownConfig config;
  final AgentChatMarkdownStyles styles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: OrderedListView(
        no: '$no.',
        textDirection: config.textDirection,
        style: styles.orderedListMarker(config.style),
        padding: 0,
        spacing: 6,
        child: child,
      ),
    );
  }
}
