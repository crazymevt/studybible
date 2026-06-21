import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/domain/search/reference_parser.dart';

void main() {
  // A small canonical set of books to resolve against.
  const books = <Book>[
    Book(id: 1, versionId: 'KJV', name: 'Genesis', bookOrder: 1, testament: 'OT'),
    Book(
      id: 2,
      versionId: 'KJV',
      name: 'Song of Solomon',
      bookOrder: 22,
      testament: 'OT',
    ),
    Book(id: 3, versionId: 'KJV', name: 'John', bookOrder: 43, testament: 'NT'),
    Book(id: 4, versionId: 'KJV', name: '1 John', bookOrder: 62, testament: 'NT'),
  ];

  group('search ReferenceParser', () {
    test('parses "Book chapter" with no verse', () {
      final ref = ReferenceParser.parse('John 3', books);
      expect(ref, isNotNull);
      expect(ref!.book.name, 'John');
      expect(ref.chapter, 3);
      expect(ref.verse, isNull);
    });

    test('parses "Book chapter:verse"', () {
      final ref = ReferenceParser.parse('Genesis 1:5', books);
      expect(ref, isNotNull);
      expect(ref!.book.name, 'Genesis');
      expect(ref.chapter, 1);
      expect(ref.verse, 5);
    });

    test('matches book names case-insensitively', () {
      final ref = ReferenceParser.parse('genesis 1', books);
      expect(ref?.book.name, 'Genesis');
    });

    test('resolves a numbered book by its normalized name', () {
      final ref = ReferenceParser.parse('1 John 2:3', books);
      expect(ref, isNotNull);
      expect(ref!.book.name, '1 John');
      expect(ref.chapter, 2);
      expect(ref.verse, 3);
    });

    test('resolves a book by prefix', () {
      final ref = ReferenceParser.parse('Gen 1', books);
      expect(ref?.book.name, 'Genesis');
    });

    test('resolves multi-word book names', () {
      final ref = ReferenceParser.parse('Song of Solomon 2:1', books);
      expect(ref, isNotNull);
      expect(ref!.book.name, 'Song of Solomon');
      expect(ref.chapter, 2);
      expect(ref.verse, 1);
    });

    test('returns null for an unknown book', () {
      expect(ReferenceParser.parse('Nonexistent 3', books), isNull);
    });

    test('returns null when chapter is not positive', () {
      expect(ReferenceParser.parse('Genesis 0', books), isNull);
    });

    test('treats a non-positive verse as no verse', () {
      final ref = ReferenceParser.parse('Genesis 3:0', books);
      expect(ref, isNotNull);
      expect(ref!.chapter, 3);
      expect(ref.verse, isNull);
    });

    test('returns null for input without a chapter number', () {
      expect(ReferenceParser.parse('John', books), isNull);
      expect(ReferenceParser.parse('garbage', books), isNull);
    });
  });
}
