import 'package:isar_plus/isar_plus.dart';

import '../helper/world_book_mapper.dart';
import '../model/world_book.dart';
import '../world_book_entity.dart';
import '../world_book_entry_entity.dart';

/// 世界书与条目的 Isar 读写仓库。
class WorldBookRepository {
  const WorldBookRepository(this._isar);

  final Isar _isar;

  List<WorldBookEntity> getWorldBooks() {
    return _sortBooks(
      _isar.collection<String, WorldBookEntity>().where().findAll(),
    );
  }

  Stream<List<WorldBookEntity>> watchWorldBooks() {
    return _isar
        .collection<String, WorldBookEntity>()
        .where()
        .watch(fireImmediately: true)
        .map(_sortBooks);
  }

  WorldBookEntity? getWorldBook(String worldBookId) {
    return _isar.collection<String, WorldBookEntity>().get(worldBookId);
  }

  List<WorldBookEntryEntity> getEntries(String worldBookId) {
    return _sortEntries(
      _isar
          .collection<String, WorldBookEntryEntity>()
          .where()
          .worldBookIdEqualTo(worldBookId)
          .findAll(),
    );
  }

  Stream<List<WorldBookEntryEntity>> watchEntries(String worldBookId) {
    return _isar
        .collection<String, WorldBookEntryEntity>()
        .where()
        .worldBookIdEqualTo(worldBookId)
        .watch(fireImmediately: true)
        .map(_sortEntries);
  }

  WorldBookEntryEntity? getEntry(String entryId) {
    return _isar.collection<String, WorldBookEntryEntity>().get(entryId);
  }

  WorldBook? getWorldBookSnapshot(String worldBookId) {
    final book = getWorldBook(worldBookId);
    if (book == null) {
      return null;
    }
    return worldBookFromEntities(book, getEntries(worldBookId));
  }

  List<WorldBook> getWorldBookSnapshots(Iterable<String> worldBookIds) {
    final result = <WorldBook>[];
    for (final id in worldBookIds) {
      final snapshot = getWorldBookSnapshot(id);
      if (snapshot != null) {
        result.add(snapshot);
      }
    }
    return result;
  }

  WorldBookEntity upsertWorldBook({
    String? worldBookId,
    required String name,
    String description = '',
    int scanDepth = 50,
    int tokenBudget = 2000,
    bool recursiveScanning = false,
  }) {
    final now = DateTime.now();
    final id = worldBookId ?? createWorldBookId();
    late WorldBookEntity book;
    _isar.write((isar) {
      final books = isar.collection<String, WorldBookEntity>();
      final existing = books.get(id);
      book =
          existing?.copyWith(
            name: name.trim(),
            description: description.trim(),
            scanDepth: scanDepth,
            tokenBudget: tokenBudget,
            recursiveScanning: recursiveScanning,
            updatedAt: now,
          ) ??
          WorldBookEntity(
            id: id,
            name: name.trim(),
            description: description.trim(),
            scanDepth: scanDepth,
            tokenBudget: tokenBudget,
            recursiveScanning: recursiveScanning,
            createdAt: now,
            updatedAt: now,
          );
      books.put(book);
    });
    return book;
  }

  /// 用完整快照覆盖写入书元数据与条目（导入用）。
  WorldBookEntity replaceWorldBookSnapshot(WorldBook snapshot) {
    final now = DateTime.now();
    late WorldBookEntity book;
    _isar.write((isar) {
      final books = isar.collection<String, WorldBookEntity>();
      final entries = isar.collection<String, WorldBookEntryEntity>();
      final existing = books.get(snapshot.id);
      book =
          existing?.copyWith(
            name: snapshot.name.trim(),
            description: snapshot.description.trim(),
            scanDepth: snapshot.scanDepth,
            tokenBudget: snapshot.tokenBudget,
            recursiveScanning: snapshot.recursiveScanning,
            updatedAt: now,
          ) ??
          WorldBookEntity(
            id: snapshot.id,
            name: snapshot.name.trim(),
            description: snapshot.description.trim(),
            scanDepth: snapshot.scanDepth,
            tokenBudget: snapshot.tokenBudget,
            recursiveScanning: snapshot.recursiveScanning,
            createdAt: now,
            updatedAt: now,
          );
      books.put(book);

      final oldEntries = entries
          .where()
          .worldBookIdEqualTo(snapshot.id)
          .findAll();
      for (final old in oldEntries) {
        entries.delete(old.id);
      }
      for (final entry in snapshot.entries) {
        entries.put(worldBookEntryToEntity(entry));
      }
    });
    return book;
  }

  WorldBookEntryEntity upsertEntry(WorldBookEntry entry) {
    late WorldBookEntryEntity entity;
    _isar.write((isar) {
      final entries = isar.collection<String, WorldBookEntryEntity>();
      final books = isar.collection<String, WorldBookEntity>();
      entity = worldBookEntryToEntity(entry);
      entries.put(entity);
      final book = books.get(entry.worldBookId);
      if (book != null) {
        books.put(book.copyWith(updatedAt: DateTime.now()));
      }
    });
    return entity;
  }

  bool deleteEntry(String entryId) {
    var deleted = false;
    _isar.write((isar) {
      final entries = isar.collection<String, WorldBookEntryEntity>();
      final existing = entries.get(entryId);
      if (existing == null) {
        return;
      }
      deleted = entries.delete(entryId);
      final book = isar.collection<String, WorldBookEntity>().get(
        existing.worldBookId,
      );
      if (book != null) {
        isar.collection<String, WorldBookEntity>().put(
          book.copyWith(updatedAt: DateTime.now()),
        );
      }
    });
    return deleted;
  }

  /// 删除世界书及其全部条目。
  bool deleteWorldBook(String worldBookId) {
    var deleted = false;
    _isar.write((isar) {
      final entries = isar.collection<String, WorldBookEntryEntity>();
      final oldEntries = entries
          .where()
          .worldBookIdEqualTo(worldBookId)
          .findAll();
      for (final entry in oldEntries) {
        entries.delete(entry.id);
      }
      deleted = isar.collection<String, WorldBookEntity>().delete(worldBookId);
    });
    return deleted;
  }

  String createWorldBookId() {
    return 'world_book_${DateTime.now().microsecondsSinceEpoch}';
  }

  String createEntryId() {
    return 'entry_${DateTime.now().microsecondsSinceEpoch}';
  }
}

List<WorldBookEntity> _sortBooks(List<WorldBookEntity> books) {
  return [...books]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}

List<WorldBookEntryEntity> _sortEntries(List<WorldBookEntryEntity> entries) {
  return [...entries]..sort((a, b) {
    final byOrder = a.insertionOrder.compareTo(b.insertionOrder);
    if (byOrder != 0) {
      return byOrder;
    }
    return a.name.compareTo(b.name);
  });
}
