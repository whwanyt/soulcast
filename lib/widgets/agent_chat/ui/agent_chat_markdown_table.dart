part of 'agent_chat_markdown.dart';

/// 可横向滚动且限制列宽的 Markdown 表格。
class _AgentChatMarkdownTable extends StatelessWidget {
  const _AgentChatMarkdownTable({
    required this.rows,
    required this.textStyle,
    required this.config,
    required this.styles,
  });

  final List<CustomTableRow> rows;
  final TextStyle textStyle;
  final GptMarkdownConfig config;
  final AgentChatMarkdownStyles styles;

  /// Soft cap so long cell text wraps instead of stretching forever.
  static const double _minColumnMaxWidth = 120;
  static const double _columnMaxWidthFactor = 1;

  @override
  Widget build(BuildContext context) {
    final chrome = styles.chrome;
    final headerStyle = styles.tableHeader(textStyle);
    final columnCount = rows.isEmpty ? 0 : rows.first.fields.length;
    final labelColor = styles.colorScheme.onSurfaceVariant;
    final markdown = _tableRowsToMarkdown(rows);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxTableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width * 0.94;
          final maxColumnWidth = (maxTableWidth * _columnMaxWidthFactor).clamp(
            _minColumnMaxWidth,
            maxTableWidth,
          );
          final columnWidths = <int, TableColumnWidth>{
            for (var i = 0; i < columnCount; i++)
              i: MinColumnWidth(
                const IntrinsicColumnWidth(),
                FixedColumnWidth(maxColumnWidth),
              ),
          };

          return Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTableWidth),
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
                              const Spacer(),
                              AgentChatCopyIconButton(
                                text: markdown,
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          columnWidths: columnWidths,
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: chrome.divider,
                              width: 1,
                            ),
                          ),
                          children: [
                            for (final row in rows)
                              TableRow(
                                decoration: row.isHeader
                                    ? BoxDecoration(color: chrome.header)
                                    : null,
                                children: [
                                  for (final field in row.fields)
                                    _AgentChatMarkdownTableCell(
                                      data: field.data,
                                      alignment: field.alignment,
                                      config: config,
                                      style: row.isHeader
                                          ? headerStyle
                                          : textStyle,
                                      isHeader: row.isHeader,
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 将表格行序列化为 Markdown，便于粘贴回编辑器。
String _tableRowsToMarkdown(List<CustomTableRow> rows) {
  if (rows.isEmpty) {
    return '';
  }

  final buffer = StringBuffer();
  for (var index = 0; index < rows.length; index++) {
    final cells = [
      for (final field in rows[index].fields)
        _escapeMarkdownTableCell(field.data),
    ];
    buffer.writeln('| ${cells.join(' | ')} |');
    if (index == 0) {
      buffer.writeln('| ${List.filled(cells.length, '---').join(' | ')} |');
    }
  }
  return buffer.toString().trimRight();
}

String _escapeMarkdownTableCell(String raw) {
  return raw.trim().replaceAll('\n', ' ').replaceAll('|', r'\|');
}

class _AgentChatMarkdownTableCell extends StatelessWidget {
  const _AgentChatMarkdownTableCell({
    required this.data,
    required this.alignment,
    required this.config,
    required this.style,
    required this.isHeader,
  });

  final String data;
  final TextAlign alignment;
  final GptMarkdownConfig config;
  final TextStyle style;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final cellConfig = config.copyWith(style: style);
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: isHeader ? 7 : AppSpacing.xs,
      ),
      child: MdWidget(context, data.trim(), false, config: cellConfig),
    );

    return switch (alignment) {
      TextAlign.center => Center(child: content),
      TextAlign.right ||
      TextAlign.end => Align(alignment: Alignment.centerRight, child: content),
      _ => Align(alignment: Alignment.centerLeft, child: content),
    };
  }
}
