import 'package:flutter/material.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

/// App-wide [syntax_highlight] bootstrap and highlighter cache.
abstract final class SyntaxHighlighterService {
  static const supportedLanguages = <String>[
    'dart',
    'yaml',
    'sql',
    'json',
    'serverpod_protocol',
  ];

  static bool _initialized = false;
  static HighlighterTheme? _lightTheme;
  static HighlighterTheme? _darkTheme;
  static final Map<String, Highlighter> _highlighters = {};

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await Highlighter.initialize(supportedLanguages);
    _lightTheme = await HighlighterTheme.loadLightTheme();
    _darkTheme = await HighlighterTheme.loadDarkTheme();
    _initialized = true;
  }

  /// Resolves a markdown fence language to a packed grammar name.
  static String? resolveLanguage(String? language) {
    final normalized = language?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'dart' => 'dart',
      'yaml' || 'yml' => 'yaml',
      'sql' => 'sql',
      'json' => 'json',
      'serverpod_protocol' || 'serverpod' => 'serverpod_protocol',
      _ => null,
    };
  }

  /// Returns a cached highlighter, or null when unavailable / unsupported.
  static Highlighter? highlighterFor({
    required String? language,
    required Brightness brightness,
  }) {
    if (!_initialized) {
      return null;
    }
    final resolved = resolveLanguage(language);
    if (resolved == null) {
      return null;
    }
    final theme = brightness == Brightness.dark ? _darkTheme : _lightTheme;
    if (theme == null) {
      return null;
    }
    final key = '$resolved:${brightness.name}';
    return _highlighters.putIfAbsent(
      key,
      () => Highlighter(language: resolved, theme: theme),
    );
  }

  /// Highlights [code] when possible; otherwise returns a plain [TextSpan].
  static TextSpan highlight({
    required String code,
    required String? language,
    required Brightness brightness,
  }) {
    final highlighter = highlighterFor(
      language: language,
      brightness: brightness,
    );
    if (highlighter == null) {
      return TextSpan(text: code);
    }
    return highlighter.highlight(code);
  }
}
