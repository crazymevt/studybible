import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/reading_plan/reference_parser.dart';

void main() {
  group('ReferenceParser', () {
    test('parses simple chapter', () {
      final ref = ReferenceParser.parse('Genesis 1');
      expect(ref.bookName, 'Genesis');
      expect(ref.startChapter, 1);
      expect(ref.endChapter, 1);
      expect(ref.startVerse, isNull);
      expect(ref.endVerse, isNull);
    });

    test('parses chapter range', () {
      final ref = ReferenceParser.parse('Genesis 9-10');
      expect(ref.bookName, 'Genesis');
      expect(ref.startChapter, 9);
      expect(ref.endChapter, 10);
      expect(ref.startVerse, isNull);
      expect(ref.endVerse, isNull);
    });

    test('parses specific verse range within a chapter', () {
      final ref = ReferenceParser.parse('Luke 1:1-38');
      expect(ref.bookName, 'Luke');
      expect(ref.startChapter, 1);
      expect(ref.endChapter, 1);
      expect(ref.startVerse, 1);
      expect(ref.endVerse, 38);
    });

    test('parses specific verse range across chapters', () {
      final ref = ReferenceParser.parse('Genesis 1:1-3:24');
      expect(ref.bookName, 'Genesis');
      expect(ref.startChapter, 1);
      expect(ref.endChapter, 3);
      expect(ref.startVerse, 1);
      expect(ref.endVerse, 24);
    });

    test('parses numbered book names correctly', () {
      final ref = ReferenceParser.parse('1 Thes 1');
      expect(ref.bookName, '1 Thessalonians');
      expect(ref.startChapter, 1);
      expect(ref.endChapter, 1);
      expect(ref.startVerse, isNull);
      expect(ref.endVerse, isNull);
      
      final ref2 = ReferenceParser.parse('1Samuel 13:6-18');
      expect(ref2.bookName, '1 Samuel');
      expect(ref2.startChapter, 13);
      expect(ref2.endChapter, 13);
      expect(ref2.startVerse, 6);
      expect(ref2.endVerse, 18);
    });

    test('normalizes known aliases', () {
      final ref = ReferenceParser.parse('SongOfSongs 1:1-8:14');
      expect(ref.bookName, 'Song of Solomon');
      expect(ref.startChapter, 1);
      expect(ref.endChapter, 8);
      expect(ref.startVerse, 1);
      expect(ref.endVerse, 14);
    });

    test('handles single verse', () {
      final ref = ReferenceParser.parse('Joshua 7:1');
      expect(ref.bookName, 'Joshua');
      expect(ref.startChapter, 7);
      expect(ref.endChapter, 7);
      expect(ref.startVerse, 1);
      expect(ref.endVerse, 1);
    });

    test('falls back to chapter 1 for a bare book name', () {
      final ref = ReferenceParser.parse('Obadiah');
      expect(ref.bookName, 'Obadiah');
      expect(ref.startChapter, 1);
      expect(ref.endChapter, 1);
      expect(ref.startVerse, isNull);
      expect(ref.endVerse, isNull);
    });

    test('normalizes a numbered book joined to its chapter', () {
      final ref = ReferenceParser.parse('1Chronicles 5');
      expect(ref.bookName, '1 Chronicles');
      expect(ref.startChapter, 5);
      expect(ref.endChapter, 5);
    });
  });

  group('ReferenceParser.normalizeBookName', () {
    test('maps known aliases to canonical names', () {
      expect(ReferenceParser.normalizeBookName('SongOfSongs'), 'Song of Solomon');
      expect(ReferenceParser.normalizeBookName('1 Cor'), '1 Corinthians');
      expect(ReferenceParser.normalizeBookName('1 Cor.'), '1 Corinthians');
      expect(ReferenceParser.normalizeBookName('2Tim'), '2 Timothy');
    });

    test('inserts a space after a leading digit', () {
      expect(ReferenceParser.normalizeBookName('1Samuel'), '1 Samuel');
    });

    test('trims whitespace', () {
      expect(ReferenceParser.normalizeBookName('  Genesis  '), 'Genesis');
    });

    test('leaves unrecognized names unchanged', () {
      expect(ReferenceParser.normalizeBookName('Genesis'), 'Genesis');
    });
  });
}
