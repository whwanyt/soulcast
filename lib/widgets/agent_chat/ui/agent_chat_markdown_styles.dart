import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// Shared chrome tokens for flat markdown surfaces (table / code / quote).
class AgentChatMarkdownChrome {
  const AgentChatMarkdownChrome(this.colorScheme);

  final ColorScheme colorScheme;

  Color get divider => colorScheme.outlineVariant.withValues(alpha: 0.4);

  Color get surface =>
      colorScheme.surfaceContainerLowest.withValues(alpha: 0.65);

  Color get header => colorScheme.surfaceContainerHigh.withValues(alpha: 0.55);

  Color get accent => colorScheme.outlineVariant.withValues(alpha: 0.85);

  BorderRadius get radius => BorderRadius.circular(AppRadii.sm);

  BoxDecoration panel({bool withBorder = true}) {
    return BoxDecoration(
      color: surface,
      borderRadius: radius,
      border: withBorder ? Border.all(color: divider) : null,
    );
  }
}

/// Chat markdown typography derived from a single body [TextStyle].
class AgentChatMarkdownStyles {
  const AgentChatMarkdownStyles({
    required this.colorScheme,
    required this.chrome,
    required this.body,
    required this.code,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.h5,
    required this.h6,
  });

  factory AgentChatMarkdownStyles.resolve({
    required ColorScheme colorScheme,
    required TextStyle base,
  }) {
    final baseSize = base.fontSize;
    final baseHeight = base.height;
    final chrome = AgentChatMarkdownChrome(colorScheme);

    TextStyle heading(FontWeight weight) {
      return base.copyWith(
        fontSize: baseSize,
        height: baseHeight,
        fontWeight: weight,
        letterSpacing: -0.15,
      );
    }

    return AgentChatMarkdownStyles(
      colorScheme: colorScheme,
      chrome: chrome,
      body: base,
      code: base.copyWith(
        height: 1.2,
        fontFamily: 'monospace',
        letterSpacing: 0,
      ),
      h1: heading(FontWeight.w700),
      h2: heading(FontWeight.w700),
      h3: heading(FontWeight.w600),
      h4: heading(FontWeight.w600),
      h5: heading(FontWeight.w600),
      h6: heading(FontWeight.w600),
    );
  }

  final ColorScheme colorScheme;
  final AgentChatMarkdownChrome chrome;
  final TextStyle body;
  final TextStyle code;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle h5;
  final TextStyle h6;

  static const double _paragraphGapScale = 0.35;
  static const double _bulletScale = 0.28;

  TextStyle inlineCode({Color? color}) {
    return code.copyWith(color: color, fontWeight: FontWeight.w500);
  }

  TextStyle codeLabel() {
    return TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: code.fontSize,
      height: code.height,
      fontWeight: FontWeight.w500,
    );
  }

  TextStyle quote([TextStyle? base]) {
    return (base ?? body).copyWith(color: colorScheme.onSurfaceVariant);
  }

  TextStyle link(TextStyle base) {
    return base.copyWith(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: colorScheme.primary.withValues(alpha: 0.4),
      decorationThickness: 1,
    );
  }

  TextStyle orderedListMarker([TextStyle? base]) {
    return (base ?? body).copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  TextStyle tableHeader([TextStyle? base]) {
    return (base ?? body).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );
  }

  TextStyle paragraphGap([TextStyle? base]) {
    final source = base ?? body;
    final fontSize = source.fontSize ?? 14;
    return TextStyle(
      fontSize: fontSize * _paragraphGapScale,
      height: 1,
      color: source.color,
    );
  }

  Color get bulletColor => colorScheme.onSurfaceVariant.withValues(alpha: 0.55);

  double bulletSize([double? fontSize]) {
    return (fontSize ?? body.fontSize ?? 14) * _bulletScale;
  }

  GptMarkdownThemeData toGptTheme(Brightness brightness) {
    return GptMarkdownThemeData(
      brightness: brightness,
      h1: h1,
      h2: h2,
      h3: h3,
      h4: h4,
      h5: h5,
      h6: h6,
      highlightColor: chrome.header,
      linkColor: colorScheme.primary,
      linkHoverColor: colorScheme.primary,
      hrLineColor: chrome.divider,
      hrLineThickness: 1,
      hrLinePadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      autoAddDividerLineAfterH1: false,
    );
  }
}
