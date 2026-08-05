import 'dart:convert';

import 'package:flute_core/log/log.dart';

/// AI 生成的角色卡草稿，用于预填编辑表单。
class GeneratedCharacterDraft {
  const GeneratedCharacterDraft({
    required this.name,
    required this.description,
    required this.personality,
    required this.speechStyle,
    required this.appearance,
    required this.scenario,
    required this.greeting,
    required this.exampleDialogues,
    required this.hardConstraints,
    this.avatarUrl,
  });

  final String name;
  final String description;
  final String personality;
  final String speechStyle;
  final String appearance;
  final String scenario;

  /// AI 生成的主开场白；应用到表单时写入 greetings 首项。
  final String greeting;
  final String exampleDialogues;
  final String hardConstraints;
  final String? avatarUrl;

  List<String> get greetings {
    final trimmed = greeting.trim();
    return trimmed.isEmpty ? const [] : [trimmed];
  }

  GeneratedCharacterDraft copyWith({
    String? name,
    String? description,
    String? personality,
    String? speechStyle,
    String? appearance,
    String? scenario,
    String? greeting,
    String? exampleDialogues,
    String? hardConstraints,
    String? avatarUrl,
  }) {
    return GeneratedCharacterDraft(
      name: name ?? this.name,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      speechStyle: speechStyle ?? this.speechStyle,
      appearance: appearance ?? this.appearance,
      scenario: scenario ?? this.scenario,
      greeting: greeting ?? this.greeting,
      exampleDialogues: exampleDialogues ?? this.exampleDialogues,
      hardConstraints: hardConstraints ?? this.hardConstraints,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

/// 解析角色卡生成器返回的 JSON；无效响应返回 `null`。
GeneratedCharacterDraft? parseGeneratedCharacterDraft(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      return null;
    }

    final map = decoded.cast<String, dynamic>();
    final name = _readString(map['name']);
    if (name == null || name.isEmpty) {
      return null;
    }

    return GeneratedCharacterDraft(
      name: name,
      description: _readString(map['description']) ?? '',
      personality: _readString(map['personality']) ?? '',
      speechStyle: _readString(map['speechStyle']) ?? '',
      appearance: _readString(map['appearance']) ?? '',
      scenario: _readString(map['scenario']) ?? '',
      greeting: _readString(map['greeting']) ?? '',
      exampleDialogues: _readString(map['exampleDialogues']) ?? '',
      hardConstraints: _readString(map['hardConstraints']) ?? '',
    );
  } catch (error, stackTrace) {
    Log.e(
      'Generated character draft parse failed: $error',
      tag: 'Character',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

String? _readString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
