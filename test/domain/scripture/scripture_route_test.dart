import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/app/scripture_nav_providers.dart';
import 'package:study_bible/domain/scripture/scripture_route.dart';

Book _book(int order, String name, String testament) => Book(
  id: order,
  versionId: 'KJV',
  name: name,
  bookOrder: order,
  testament: testament,
);

void main() {
  group('ScriptureRouteStop.label', () {
    test('chapter and verse', () {
      const stop = ScriptureRouteStop(bookName: 'John', chapter: 3, verse: 16);
      expect(stop.label, 'John 3:16');
    });

    test('chapter only', () {
      const stop = ScriptureRouteStop(bookName: 'Psalms', chapter: 23);
      expect(stop.label, 'Psalms 23');
    });

    test('verse range within a chapter', () {
      const stop = ScriptureRouteStop(
        bookName: 'Romans',
        chapter: 8,
        verse: 28,
        endChapter: 8,
        endVerse: 30,
      );
      expect(stop.label, 'Romans 8:28–30');
    });

    test('range across chapters', () {
      const stop = ScriptureRouteStop(
        bookName: 'Genesis',
        chapter: 1,
        verse: 1,
        endChapter: 2,
        endVerse: 3,
      );
      expect(stop.label, 'Genesis 1:1–2:3');
    });

    test('chapter range without verses', () {
      const stop = ScriptureRouteStop(
        bookName: 'Isaiah',
        chapter: 9,
        endChapter: 10,
      );
      expect(stop.label, 'Isaiah 9–10');
    });
  });

  group('stopHighlightVerses', () {
    final chapterVerses = List.generate(31, (i) => i + 1); // verses 1..31

    test('single verse', () {
      const stop = ScriptureRouteStop(bookName: 'John', chapter: 3, verse: 16);
      expect(
        stopHighlightVerses(stop, 'John', 3, chapterVerses),
        {16},
      );
    });

    test('wrong book or chapter yields nothing', () {
      const stop = ScriptureRouteStop(bookName: 'John', chapter: 3, verse: 16);
      expect(stopHighlightVerses(stop, 'Mark', 3, chapterVerses), isEmpty);
      expect(stopHighlightVerses(stop, 'John', 4, chapterVerses), isEmpty);
    });

    test('chapter-only stop covers the whole chapter', () {
      const stop = ScriptureRouteStop(bookName: 'Psalms', chapter: 23);
      expect(
        stopHighlightVerses(stop, 'Psalms', 23, [1, 2, 3, 4, 5, 6]),
        {1, 2, 3, 4, 5, 6},
      );
    });

    test('range within a chapter', () {
      const stop = ScriptureRouteStop(
        bookName: 'Romans',
        chapter: 8,
        verse: 28,
        endChapter: 8,
        endVerse: 30,
      );
      expect(
        stopHighlightVerses(stop, 'Romans', 8, chapterVerses),
        {28, 29, 30},
      );
    });

    test('cross-chapter range highlights each chapter correctly', () {
      const stop = ScriptureRouteStop(
        bookName: 'Genesis',
        chapter: 1,
        verse: 29,
        endChapter: 3,
        endVerse: 2,
      );
      // First chapter: from the start verse to the chapter's end.
      expect(
        stopHighlightVerses(stop, 'Genesis', 1, chapterVerses),
        {29, 30, 31},
      );
      // Middle chapter: everything.
      expect(
        stopHighlightVerses(stop, 'Genesis', 2, [1, 2, 3]),
        {1, 2, 3},
      );
      // Last chapter: up to the end verse.
      expect(
        stopHighlightVerses(stop, 'Genesis', 3, chapterVerses),
        {1, 2},
      );
      // Outside the range.
      expect(stopHighlightVerses(stop, 'Genesis', 4, chapterVerses), isEmpty);
    });
  });

  group('dedupeConsecutiveStops', () {
    const a = ScriptureRouteStop(bookName: 'John', chapter: 3, verse: 16);
    const b = ScriptureRouteStop(bookName: 'Romans', chapter: 8, verse: 28);

    test('collapses immediate repeats but keeps later returns', () {
      expect(dedupeConsecutiveStops([a, a, b, b, a]), [a, b, a]);
    });

    test('empty list stays empty', () {
      expect(dedupeConsecutiveStops([]), isEmpty);
    });
  });

  group('scanSermonRoute', () {
    final books = [
      _book(19, 'Psalms', 'OT'),
      _book(43, 'John', 'NT'),
      _book(45, 'Romans', 'NT'),
    ];

    test('builds stops in document order, keeping chapter-only refs', () {
      const text =
          'Open your Bibles to John 3:16. As Romans 8:28-30 promises... '
          'We close in Psalm 23.';
      final stops = scanSermonRoute(text, books);
      expect(stops.map((s) => s.label).toList(), [
        'John 3:16',
        'Romans 8:28–30',
        'Psalms 23',
      ]);
    });

    test('collapses an immediately repeated citation', () {
      const text = 'John 3:16 — yes, John 3:16! But also Romans 8:28.';
      final stops = scanSermonRoute(text, books);
      expect(stops.map((s) => s.label).toList(), [
        'John 3:16',
        'Romans 8:28',
      ]);
    });

    test('no references yields an empty route', () {
      expect(scanSermonRoute('A sermon with no citations.', books), isEmpty);
    });
  });
}
