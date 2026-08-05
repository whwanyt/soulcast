import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/world_book/world_book.dart';
import 'package:soulcast/features/chat/service/character_book_resolver.dart';

void main() {
  const resolver = CharacterBookResolver();

  test('includes constant entries and keyword matches', () {
    const book = WorldBook(
      id: 'book_1',
      scanDepth: 10,
      tokenBudget: 2000,
      entries: [
        WorldBookEntry(
          id: '1',
          worldBookId: 'book_1',
          keys: [],
          content: 'always on',
          constant: true,
          position: WorldBookPosition.beforeChar,
        ),
        WorldBookEntry(
          id: '2',
          worldBookId: 'book_1',
          keys: ['Chandra'],
          content: 'military advisor',
          position: WorldBookPosition.afterChar,
          priority: 20,
        ),
        WorldBookEntry(
          id: '3',
          worldBookId: 'book_1',
          keys: ['Medli'],
          content: 'trade advisor',
          position: WorldBookPosition.beforeChar,
        ),
      ],
    );

    final resolution = resolver.resolve(
      book: book,
      messages: [
        ChatConversationMessage.user('I will speak with Chandra today.'),
      ],
    );

    expect(resolution.beforeChar, contains('always on'));
    expect(resolution.beforeChar, isNot(contains('trade advisor')));
    expect(resolution.afterChar, contains('military advisor'));
  });

  test('respects token budget after first entry', () {
    const book = WorldBook(
      id: 'book_1',
      tokenBudget: 5,
      entries: [
        WorldBookEntry(
          id: '1',
          worldBookId: 'book_1',
          content: 'aaaa', // ~1 token
          constant: true,
          priority: 100,
          insertionOrder: 1,
        ),
        WorldBookEntry(
          id: '2',
          worldBookId: 'book_1',
          content: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', // large
          constant: true,
          priority: 90,
          insertionOrder: 2,
        ),
      ],
    );

    final resolution = resolver.resolve(book: book, messages: const []);
    expect(resolution.beforeChar, 'aaaa');
    expect(resolution.beforeChar, isNot(contains('bbbb')));
  });

  test('selective AND requires secondary keys', () {
    const book = WorldBook(
      id: 'book_1',
      entries: [
        WorldBookEntry(
          id: '1',
          worldBookId: 'book_1',
          keys: ['Guilder'],
          secondaryKeys: ['coin'],
          selective: true,
          content: 'currency lore',
        ),
      ],
    );

    final miss = resolver.resolve(
      book: book,
      messages: [ChatConversationMessage.user('Guilder is nearby')],
    );
    expect(miss.beforeChar, isEmpty);

    final hit = resolver.resolve(
      book: book,
      messages: [ChatConversationMessage.user('Guilder coin purse')],
    );
    expect(hit.beforeChar, contains('currency lore'));
  });

  test('resolveAll merges books in order', () {
    const primary = WorldBook(
      id: 'primary',
      entries: [
        WorldBookEntry(
          id: 'p1',
          worldBookId: 'primary',
          content: 'from primary',
          constant: true,
        ),
      ],
    );
    const session = WorldBook(
      id: 'session',
      entries: [
        WorldBookEntry(
          id: 's1',
          worldBookId: 'session',
          content: 'from session',
          constant: true,
        ),
      ],
    );

    final resolution = resolver.resolveAll(
      books: [primary, session],
      messages: const [],
    );
    expect(resolution.beforeChar, contains('from primary'));
    expect(resolution.beforeChar, contains('from session'));
  });
}
