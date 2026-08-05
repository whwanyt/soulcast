import 'dart:math';

import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/world_book/world_book.dart';

/// 世界书匹配结果，按插入位置拆分。
class CharacterBookResolution {
  const CharacterBookResolution({this.beforeChar = '', this.afterChar = ''});

  final String beforeChar;
  final String afterChar;

  bool get isEmpty => beforeChar.trim().isEmpty && afterChar.trim().isEmpty;

  CharacterBookResolution merge(CharacterBookResolution other) {
    return CharacterBookResolution(
      beforeChar: [beforeChar, other.beforeChar]
          .map((text) => text.trim())
          .where((text) => text.isNotEmpty)
          .join('\n\n'),
      afterChar: [afterChar, other.afterChar]
          .map((text) => text.trim())
          .where((text) => text.isNotEmpty)
          .join('\n\n'),
    );
  }
}

/// 根据近期对话文本解析世界书命中条目。
class CharacterBookResolver {
  const CharacterBookResolver({this.random});

  /// 概率条目可注入，便于单测。
  final Random? random;

  /// 多本书各自按自身 budget 解析后拼接。
  CharacterBookResolution resolveAll({
    required List<WorldBook> books,
    required List<ChatConversationMessage> messages,
  }) {
    var combined = const CharacterBookResolution();
    for (final book in books) {
      combined = combined.merge(resolve(book: book, messages: messages));
    }
    return combined;
  }

  CharacterBookResolution resolve({
    required WorldBook book,
    required List<ChatConversationMessage> messages,
  }) {
    if (book.entries.isEmpty) {
      return const CharacterBookResolution();
    }

    final scanText = _buildScanText(messages, book.scanDepth);
    final matched = <WorldBookEntry>[];
    final matchedIds = <String>{};

    void consider(WorldBookEntry entry, String haystack) {
      if (!entry.enabled || matchedIds.contains(entry.id)) {
        return;
      }
      if (!_matchesEntry(entry, haystack)) {
        return;
      }
      if (!_passesProbability(entry)) {
        return;
      }
      matched.add(entry);
      matchedIds.add(entry.id);
    }

    for (final entry in book.entries) {
      if (entry.constant) {
        consider(entry, scanText);
      }
    }
    for (final entry in book.entries) {
      if (!entry.constant) {
        consider(entry, scanText);
      }
    }

    if (book.recursiveScanning) {
      var rounds = 0;
      while (rounds < 3) {
        rounds += 1;
        final beforeCount = matched.length;
        final recursiveHaystack = matched.map((e) => e.content).join('\n');
        for (final entry in book.entries) {
          consider(entry, recursiveHaystack);
        }
        if (matched.length == beforeCount) {
          break;
        }
      }
    }

    matched.sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) {
        return byPriority;
      }
      return a.insertionOrder.compareTo(b.insertionOrder);
    });

    final before = <String>[];
    final after = <String>[];
    var usedTokens = 0;
    final budget = book.tokenBudget <= 0 ? 2000 : book.tokenBudget;

    for (final entry in matched) {
      final content = entry.content.trim();
      if (content.isEmpty) {
        continue;
      }
      final cost = _estimateTokens(content);
      if (usedTokens + cost > budget &&
          (before.isNotEmpty || after.isNotEmpty)) {
        break;
      }
      usedTokens += cost;
      if (entry.position == WorldBookPosition.afterChar) {
        after.add(content);
      } else {
        before.add(content);
      }
    }

    return CharacterBookResolution(
      beforeChar: before.join('\n\n'),
      afterChar: after.join('\n\n'),
    );
  }

  String _buildScanText(List<ChatConversationMessage> messages, int scanDepth) {
    final depth = scanDepth <= 0 ? 50 : scanDepth;
    final candidates = messages
        .where(
          (message) =>
              message.role == ChatConversationRole.user ||
              message.role == ChatConversationRole.assistant,
        )
        .toList(growable: false);
    final start = candidates.length > depth ? candidates.length - depth : 0;
    return candidates
        .sublist(start)
        .map((message) => message.content.trim())
        .where((content) => content.isNotEmpty)
        .join('\n');
  }

  bool _matchesEntry(WorldBookEntry entry, String haystack) {
    if (entry.constant) {
      return true;
    }
    if (haystack.isEmpty) {
      return false;
    }
    final primaryHit = _anyKeyMatches(
      entry.keys,
      haystack,
      entry.caseSensitive,
    );
    if (!primaryHit) {
      return false;
    }
    if (!entry.selective || entry.secondaryKeys.isEmpty) {
      return true;
    }
    if (entry.selectiveLogic == WorldBookSelectiveLogic.or) {
      return _anyKeyMatches(entry.secondaryKeys, haystack, entry.caseSensitive);
    }
    return _allKeysMatch(entry.secondaryKeys, haystack, entry.caseSensitive);
  }

  bool _anyKeyMatches(List<String> keys, String haystack, bool caseSensitive) {
    for (final key in keys) {
      final needle = key.trim();
      if (needle.isEmpty) {
        continue;
      }
      if (_contains(haystack, needle, caseSensitive)) {
        return true;
      }
    }
    return false;
  }

  bool _allKeysMatch(List<String> keys, String haystack, bool caseSensitive) {
    final nonEmpty = keys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toList(growable: false);
    if (nonEmpty.isEmpty) {
      return true;
    }
    for (final key in nonEmpty) {
      if (!_contains(haystack, key, caseSensitive)) {
        return false;
      }
    }
    return true;
  }

  bool _contains(String haystack, String needle, bool caseSensitive) {
    if (caseSensitive) {
      return haystack.contains(needle);
    }
    return haystack.toLowerCase().contains(needle.toLowerCase());
  }

  bool _passesProbability(WorldBookEntry entry) {
    if (!entry.useProbability) {
      return true;
    }
    final probability = entry.probability.clamp(0, 100);
    if (probability >= 100) {
      return true;
    }
    if (probability <= 0) {
      return false;
    }
    final rng = random ?? Random();
    return rng.nextInt(100) < probability;
  }

  int _estimateTokens(String text) {
    return max(1, (text.length / 4).ceil());
  }
}
