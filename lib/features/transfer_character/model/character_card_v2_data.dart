import 'package:soulcast/entities/world_book/world_book.dart';

/// SillyTavern `chara_card_v2` 解码后的稳定中间结构。
class CharacterCardV2Data {
  const CharacterCardV2Data({
    required this.name,
    this.description = '',
    this.personality = '',
    this.scenario = '',
    this.firstMes = '',
    this.mesExample = '',
    this.systemPrompt = '',
    this.postHistoryInstructions = '',
    this.creatorNotes = '',
    this.creator = '',
    this.characterVersion = '',
    this.tags = const [],
    this.alternateGreetings = const [],
    this.characterBook,
    this.avatarUrl,
    this.speechStyle = '',
    this.appearance = '',
    this.hardConstraints = '',
  });

  final String name;
  final String description;
  final String personality;
  final String scenario;
  final String firstMes;
  final String mesExample;
  final String systemPrompt;
  final String postHistoryInstructions;
  final String creatorNotes;
  final String creator;
  final String characterVersion;
  final List<String> tags;
  final List<String> alternateGreetings;
  final WorldBook? characterBook;
  final String? avatarUrl;
  final String speechStyle;
  final String appearance;
  final String hardConstraints;

  List<String> get greetings {
    final result = <String>[];
    final primary = firstMes.trim();
    if (primary.isNotEmpty) {
      result.add(primary);
    }
    for (final item in alternateGreetings) {
      final trimmed = item.trim();
      if (trimmed.isNotEmpty) {
        result.add(trimmed);
      }
    }
    return result;
  }
}
