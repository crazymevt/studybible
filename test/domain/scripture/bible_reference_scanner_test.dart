import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/domain/scripture/bible_reference_scanner.dart';

Book _book(int order, String name, String testament) => Book(
  id: order,
  versionId: 'KJV',
  name: name,
  bookOrder: order,
  testament: testament,
);

void main() {
  final books = [
    _book(1, 'Genesis', 'OT'),
    _book(19, 'Psalms', 'OT'),
    _book(22, 'Song of Solomon', 'OT'),
    _book(23, 'Isaiah', 'OT'),
    _book(40, 'Matthew', 'NT'),
    _book(41, 'Mark', 'NT'),
    _book(43, 'John', 'NT'),
    _book(45, 'Romans', 'NT'),
    _book(46, '1 Corinthians', 'NT'),
    _book(55, '2 Timothy', 'NT'),
    _book(62, '1 John', 'NT'),
    _book(66, 'Revelation', 'NT'),
  ];

  List<ReferenceMatch> scan(String text, {bool requireVerse = false}) =>
      BibleReferenceScanner.scan(text, books, requireVerse: requireVerse);

  // Convenience: the substring the scanner claims it matched.
  String matched(String text, ReferenceMatch m) => text.substring(m.start, m.end);

  group('single reference in prose', () {
    test('chapter and verse', () {
      const text = 'As Paul writes in Romans 8:28, all things work together.';
      final refs = scan(text);
      expect(refs, hasLength(1));
      expect(refs.single.book.name, 'Romans');
      expect(refs.single.chapter, 8);
      expect(refs.single.verse, 28);
      expect(matched(text, refs.single), 'Romans 8:28');
    });

    test('numbered book with abbreviation', () {
      const text = 'See 1 Cor 13:4 for the definition of love.';
      final refs = scan(text);
      expect(refs, hasLength(1));
      expect(refs.single.book.name, '1 Corinthians');
      expect(refs.single.chapter, 13);
      expect(refs.single.verse, 4);
    });

    test('multi-word book name', () {
      const text = 'Song of Solomon 2:1 is often quoted at weddings.';
      final refs = scan(text);
      expect(refs, hasLength(1));
      expect(refs.single.book.name, 'Song of Solomon');
      expect(refs.single.chapter, 2);
      expect(refs.single.verse, 1);
    });

    test('prefix abbreviation resolves', () {
      final refs = scan('Rev 22:20 closes the canon.');
      expect(refs.single.book.name, 'Revelation');
      expect(refs.single.chapter, 22);
      expect(refs.single.verse, 20);
    });
  });

  group('ranges', () {
    test('verse range within a chapter', () {
      final refs = scan('Meditate on Romans 8:28-30 today.');
      final m = refs.single;
      expect(m.chapter, 8);
      expect(m.verse, 28);
      expect(m.endChapter, 8);
      expect(m.endVerse, 30);
    });

    test('cross-chapter range', () {
      const text = 'Read Genesis 1:1-2:3 for the creation account.';
      final m = scan(text).single;
      expect(m.chapter, 1);
      expect(m.verse, 1);
      expect(m.endChapter, 2);
      expect(m.endVerse, 3);
      expect(matched(text, m), 'Genesis 1:1-2:3');
    });
  });

  group('multiple references', () {
    test('finds each in order', () {
      final refs =
          scan('Compare John 3:16 with Romans 5:8 and 1 John 4:9.');
      expect(refs.map((r) => r.book.name), ['John', 'Romans', '1 John']);
      expect(refs.map((r) => r.verse), [16, 8, 9]);
    });
  });

  group('chapter-only references', () {
    test('are returned by default', () {
      final refs = scan('The whole of Genesis 1 sets the stage.');
      expect(refs.single.book.name, 'Genesis');
      expect(refs.single.chapter, 1);
      expect(refs.single.verse, isNull);
    });

    test('are dropped when requireVerse is set', () {
      expect(scan('The whole of Genesis 1 sets the stage.', requireVerse: true),
          isEmpty);
      // ...but a verse-bearing reference still comes through.
      expect(
        scan('Genesis 1:1 in the beginning.', requireVerse: true),
        hasLength(1),
      );
    });
  });

  group('false positives are avoided', () {
    test('plain numbers with no book', () {
      expect(scan('The meeting is at 3:15 and lasts 2 hours.'), isEmpty);
      expect(scan('A ratio of 1:1 is balanced.'), isEmpty);
    });

    test('unknown capitalized word before a number', () {
      expect(scan('Room 3 is down the hall.'), isEmpty);
      expect(scan('Chapter 5 was hard to read.'), isEmpty);
    });

    test('book name as an ordinary word without a verse is safe under requireVerse', () {
      // "Mark 5 boxes" — chapter-only, so requireVerse drops it.
      expect(scan('Please Mark 5 boxes on the form.', requireVerse: true),
          isEmpty);
    });

    test('word boundary — no match glued to letters/digits', () {
      expect(scan('emailJohn 3 times'), isEmpty);
    });
  });

  test('empty book list yields nothing', () {
    expect(BibleReferenceScanner.scan('Romans 8:28', const []), isEmpty);
  });
}
