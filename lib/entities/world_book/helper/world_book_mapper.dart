import '../model/world_book.dart';
import '../world_book_entity.dart';
import '../world_book_entry_entity.dart';

/// 实体 ↔ 领域模型映射。
WorldBook worldBookFromEntities(
  WorldBookEntity book,
  List<WorldBookEntryEntity> entries,
) {
  return WorldBook(
    id: book.id,
    name: book.name,
    description: book.description,
    scanDepth: book.scanDepth,
    tokenBudget: book.tokenBudget,
    recursiveScanning: book.recursiveScanning,
    entries: entries.map(worldBookEntryFromEntity).toList(growable: false),
  );
}

WorldBookEntry worldBookEntryFromEntity(WorldBookEntryEntity entity) {
  return WorldBookEntry(
    id: entity.id,
    worldBookId: entity.worldBookId,
    name: entity.name,
    keys: entity.keys,
    secondaryKeys: entity.secondaryKeys,
    content: entity.content,
    enabled: entity.enabled,
    constant: entity.constant,
    selective: entity.selective,
    selectiveLogic: entity.selectiveLogic == 'or'
        ? WorldBookSelectiveLogic.or
        : WorldBookSelectiveLogic.and,
    insertionOrder: entity.insertionOrder,
    priority: entity.priority,
    position: entity.position == 'after_char'
        ? WorldBookPosition.afterChar
        : WorldBookPosition.beforeChar,
    caseSensitive: entity.caseSensitive,
    probability: entity.probability,
    useProbability: entity.useProbability,
    depth: entity.depth,
    weight: entity.weight,
    comment: entity.comment,
  );
}

WorldBookEntryEntity worldBookEntryToEntity(WorldBookEntry entry) {
  return WorldBookEntryEntity(
    id: entry.id,
    worldBookId: entry.worldBookId,
    name: entry.name,
    keys: entry.keys,
    secondaryKeys: entry.secondaryKeys,
    content: entry.content,
    enabled: entry.enabled,
    constant: entry.constant,
    selective: entry.selective,
    selectiveLogic: entry.selectiveLogic == WorldBookSelectiveLogic.or
        ? 'or'
        : 'and',
    insertionOrder: entry.insertionOrder,
    priority: entry.priority,
    position: entry.position == WorldBookPosition.afterChar
        ? 'after_char'
        : 'before_char',
    caseSensitive: entry.caseSensitive,
    probability: entry.probability,
    useProbability: entry.useProbability,
    depth: entry.depth,
    weight: entry.weight,
    comment: entry.comment,
  );
}
