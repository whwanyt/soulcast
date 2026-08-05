import 'dart:convert';

import '../model/world_book.dart';

/// SillyTavern `character_book` / lorebook JSON ↔ 领域模型。
Map<String, dynamic> worldBookToJson(WorldBook book) {
  return {
    'name': book.name,
    'description': book.description,
    'scan_depth': book.scanDepth,
    'token_budget': book.tokenBudget,
    'recursive_scanning': book.recursiveScanning,
    'entries': book.entries.map(worldBookEntryToJson).toList(),
  };
}

/// 从 ST JSON 解析世界书快照；[worldBookId] 用于生成条目归属。
WorldBook worldBookFromJson(
  Map<String, dynamic> json, {
  required String worldBookId,
}) {
  final entriesRaw = json['entries'];
  final entries = <WorldBookEntry>[];
  if (entriesRaw is List) {
    var index = 0;
    for (final item in entriesRaw) {
      if (item is Map) {
        entries.add(
          worldBookEntryFromJson(
            item.cast<String, dynamic>(),
            worldBookId: worldBookId,
            fallbackIndex: index,
          ),
        );
        index += 1;
      }
    }
  }
  return WorldBook(
    id: worldBookId,
    name: _readString(json['name']) ?? '',
    description: _readString(json['description']) ?? '',
    scanDepth: _readInt(json['scan_depth']) ?? 50,
    tokenBudget: _readInt(json['token_budget']) ?? 2000,
    recursiveScanning: _readBool(json['recursive_scanning']) ?? false,
    entries: entries,
  );
}

Map<String, dynamic> worldBookEntryToJson(WorldBookEntry entry) {
  return {
    'id': entry.id,
    'name': entry.name,
    'keys': entry.keys,
    'secondary_keys': entry.secondaryKeys,
    'content': entry.content,
    'enabled': entry.enabled,
    'constant': entry.constant,
    'selective': entry.selective,
    'selectiveLogic': entry.selectiveLogic == WorldBookSelectiveLogic.or
        ? 'AND_ANY'
        : 'AND_ALL',
    'insertion_order': entry.insertionOrder,
    'priority': entry.priority,
    'position': entry.position == WorldBookPosition.afterChar
        ? 'after_char'
        : 'before_char',
    'case_sensitive': entry.caseSensitive,
    'probability': entry.probability,
    'comment': entry.comment,
    'extensions': {
      'depth': entry.depth,
      'weight': entry.weight,
      'probability': entry.probability,
      'useProbability': entry.useProbability,
      'position': entry.position == WorldBookPosition.afterChar ? 1 : 0,
    },
  };
}

WorldBookEntry worldBookEntryFromJson(
  Map<String, dynamic> json, {
  required String worldBookId,
  int fallbackIndex = 0,
}) {
  final extensions = json['extensions'];
  final ext = extensions is Map
      ? extensions.cast<String, dynamic>()
      : const <String, dynamic>{};

  final selectiveLogicRaw =
      _readString(json['selectiveLogic']) ??
      _readString(json['selective_logic']) ??
      '';
  final selectiveLogic = selectiveLogicRaw.toUpperCase().contains('ANY')
      ? WorldBookSelectiveLogic.or
      : WorldBookSelectiveLogic.and;

  final positionRaw =
      _readString(json['position']) ?? _readString(ext['position']);
  final position = _parsePosition(positionRaw, ext['position']);

  final rawId = json['id'];
  final id = rawId == null
      ? 'entry_${worldBookId}_$fallbackIndex'
      : 'entry_${worldBookId}_$rawId';

  return WorldBookEntry(
    id: id,
    worldBookId: worldBookId,
    name: _readString(json['name']) ?? '',
    keys: _readStringList(json['keys']),
    secondaryKeys: _readStringList(
      json['secondary_keys'] ?? json['secondaryKeys'],
    ),
    content: _readString(json['content']) ?? '',
    enabled: _readBool(json['enabled']) ?? true,
    constant: _readBool(json['constant']) ?? false,
    selective: _readBool(json['selective']) ?? false,
    selectiveLogic: selectiveLogic,
    insertionOrder:
        _readInt(json['insertion_order'] ?? json['insertionOrder']) ?? 100,
    priority: _readInt(json['priority']) ?? 10,
    position: position,
    caseSensitive:
        _readBool(json['case_sensitive'] ?? json['caseSensitive']) ?? false,
    probability: _readInt(json['probability'] ?? ext['probability']) ?? 100,
    useProbability:
        _readBool(ext['useProbability'] ?? ext['use_probability']) ?? false,
    depth: _readInt(ext['depth']) ?? 4,
    weight: _readInt(ext['weight']) ?? 10,
    comment: _readString(json['comment']) ?? '',
  );
}

String encodeWorldBookJson(WorldBook book) {
  return const JsonEncoder.withIndent('  ').convert(worldBookToJson(book));
}

WorldBookPosition _parsePosition(String? raw, Object? extPosition) {
  if (raw != null) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.contains('after')) {
      return WorldBookPosition.afterChar;
    }
    if (normalized.contains('before')) {
      return WorldBookPosition.beforeChar;
    }
  }
  if (extPosition is int && extPosition == 1) {
    return WorldBookPosition.afterChar;
  }
  if (extPosition is String && extPosition.trim() == '1') {
    return WorldBookPosition.afterChar;
  }
  return WorldBookPosition.beforeChar;
}

String? _readString(Object? value) {
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return null;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

bool? _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }
  if (value is num) {
    return value != 0;
  }
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
