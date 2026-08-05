import 'package:flutter/material.dart';
import 'package:nf_extended_text_field/nf_extended_text_field.dart';
import 'package:soulcast/features/chat/chat.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 将完整路由关键字渲染为带背景标签（输入框内不展示 `@`）。
class MainChatCreateImageSpecialTextSpanBuilder
    extends RegExpSpecialTextSpanBuilder {
  MainChatCreateImageSpecialTextSpanBuilder({
    required this.mentionStyle,
    required this.backgroundColor,
  });

  final TextStyle mentionStyle;
  final Color backgroundColor;

  @override
  List<RegExpSpecialText> get regExps => [
    _CreateImageMentionRegExp(
      mentionStyle: mentionStyle,
      backgroundColor: backgroundColor,
    ),
  ];
}

class _CreateImageMentionRegExp extends RegExpSpecialText {
  _CreateImageMentionRegExp({
    required this.mentionStyle,
    required this.backgroundColor,
  });

  final TextStyle mentionStyle;
  final Color backgroundColor;

  @override
  RegExp get regExp => ChatCreateImageMention.pattern;

  @override
  InlineSpan finishText(
    int start,
    Match match, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    final actualText = match.group(0)!;
    final displayLabel = actualText.startsWith('@')
        ? actualText.substring(1)
        : actualText;
    // WidgetSpan 保证背景可见；actualText 仍为完整路由关键字。
    return ExtendedWidgetSpan(
      actualText: actualText,
      start: start,
      alignment: PlaceholderAlignment.middle,
      deleteAll: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Text(
          displayLabel,
          style: mentionStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
