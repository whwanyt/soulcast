import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';
import 'package:gpt_markdown/custom_widgets/unordered_ordered_list.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/syntax_highlight/syntax_highlighter_service.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';
import 'package:soulcast/shared/widgets/weather_bg/weather_bg.dart';

import 'agent_chat_clipboard.dart';
import 'agent_chat_image_gallery.dart';
import 'agent_chat_markdown_styles.dart';

export 'agent_chat_clipboard.dart';
export 'agent_chat_markdown_styles.dart';

part 'agent_chat_markdown_image.dart';
part 'agent_chat_amap_map_md.dart';
part 'agent_chat_amap_weather_md.dart';
part 'agent_chat_markdown_blockquote.dart';
part 'agent_chat_markdown_list_items.dart';
part 'agent_chat_markdown_code.dart';
part 'agent_chat_markdown_latex.dart';
part 'agent_chat_markdown_table.dart';

/// 聊天消息 Markdown 渲染器，统一代码、表格、引用、图片和业务标签扩展。
class AgentChatMessageThemedMarkdown extends StatelessWidget {
  const AgentChatMessageThemedMarkdown({
    super.key,
    required this.data,
    required this.style,
    required this.textScaler,
  });

  final String data;
  final TextStyle? style;
  final TextScaler textScaler;

  static final List<MarkdownComponent> _components = [
    CodeBlockMd(),
    _AgentChatLatexMathMultiLine(),
    _AgentChatAmapMapMd(),
    _AgentChatAmapWeatherMd(),
    _AgentChatTightNewLines(),
    _AgentChatBlockQuoteMd(),
    TableMd(),
    HTag(),
    UnOrderedList(),
    OrderedList(),
    RadioButtonMd(),
    CheckBoxMd(),
    HrLine(),
    IndentMd(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styles = AgentChatMarkdownStyles.resolve(
      colorScheme: theme.colorScheme,
      base: style ?? DefaultTextStyle.of(context).style,
    );
    final chrome = styles.chrome;

    return GptMarkdownTheme(
      gptThemeData: styles.toGptTheme(theme.brightness),
      child: GptMarkdown(
        data,
        style: styles.body,
        textScaler: textScaler,
        components: _components,
        imageBuilder: (context, url, width, height) {
          return _AgentChatMarkdownImage(
            url: url,
            width: width,
            height: height,
            chrome: chrome,
          );
        },
        codeBuilder: (context, name, code, closed) {
          return _AgentChatMarkdownCodeBlock(
            name: name,
            code: code,
            styles: styles,
          );
        },
        tableBuilder: (context, tableRows, textStyle, config) {
          return _AgentChatMarkdownTable(
            rows: tableRows,
            textStyle: textStyle,
            config: config,
            styles: styles,
          );
        },
        highlightBuilder: (context, text, style) {
          return _AgentChatMarkdownInlineCode(
            text: text,
            style: styles.inlineCode(color: style.color),
            chrome: chrome,
          );
        },
        unOrderedListBuilder: (context, child, config) {
          return _AgentChatMarkdownUnorderedItem(
            config: config,
            styles: styles,
            child: child,
          );
        },
        orderedListBuilder: (context, no, child, config) {
          return _AgentChatMarkdownOrderedItem(
            no: no,
            config: config,
            styles: styles,
            child: child,
          );
        },
        linkBuilder: (context, text, url, style) {
          return Text.rich(text, style: styles.link(style));
        },
      ),
    );
  }
}
