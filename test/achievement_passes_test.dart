import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/data/user_store.dart';

/// Read counts for every canonical chapter set to [times].
Map<String, int> _wholeBibleReadCounts(int times) {
  final counts = <String, int>{};
  bibleChapters.forEach((book, chapters) {
    for (int c = 1; c <= chapters; c++) {
      counts['${book}_$c'] = times;
    }
  });
  return counts;
}

/// A reading-progress row for [book] chapter [chapter] read at [readAt] ms.
ReadingProgress _read(
  String book,
  int chapter,
  int readAt, {
  int iteration = 1,
}) {
  return ReadingProgress(
    id: '$book|$chapter|$iteration|$readAt',
    updatedAt: readAt,
    deviceId: 'test-device',
    deleted: false,
    bookName: book,
    chapter: chapter,
    readAt: readAt,
    iteration: iteration,
  );
}

/// Milliseconds for a local wall-clock time on the given day.
int _at(int year, int month, int day, {int hour = 12}) =>
    DateTime(year, month, day, hour).millisecondsSinceEpoch;

/// Every chapter of [book] read at the given [readAts] (one per chapter).
List<ReadingProgress> _wholeBook(String book, List<int> readAts, {int iteration = 1}) {
  final chapters = bibleChapters[book]!;
  assert(readAts.length == chapters);
  return [
    for (int c = 1; c <= chapters; c++) _read(book, c, readAts[c - 1], iteration: iteration),
  ];
}

void main() {
  group('completedBiblePasses', () {
    test('no reading yet -> 0 passes', () {
      expect(completedBiblePasses({}), 0);
    });

    test('whole Bible read once -> 1 pass', () {
      expect(completedBiblePasses(_wholeBibleReadCounts(1)), 1);
    });

    test('whole Bible read three times -> 3 passes', () {
      expect(completedBiblePasses(_wholeBibleReadCounts(3)), 3);
    });

    test('one missing chapter blocks the pass', () {
      final counts = _wholeBibleReadCounts(1);
      counts.remove('John_3'); // never read
      expect(completedBiblePasses(counts), 0);
    });

    test('re-reading a single chapter cannot inflate the count', () {
      // Whole Bible once, but one chapter hammered 50 times.
      final counts = _wholeBibleReadCounts(1);
      counts['Psalms_23'] = 50;
      expect(completedBiblePasses(counts), 1);
    });

    test('counts the floor across all chapters', () {
      // Everything read twice except one chapter read once -> only 1 full pass.
      final counts = _wholeBibleReadCounts(2);
      counts['Obadiah_1'] = 1;
      expect(completedBiblePasses(counts), 1);
    });
  });

  group('anyBookReadInOneDay / bookReadInOneDay', () {
    test('no reading -> false', () {
      expect(anyBookReadInOneDay([]), isFalse);
    });

    test('single-chapter book (Jude) read in one day counts', () {
      // Regression: the old code gated on chapters >= 3, so single-chapter
      // books like Jude could never earn "In One Sitting".
      final progress = _wholeBook('Jude', [_at(2026, 7, 1)]);
      expect(bookReadInOneDay('Jude', progress), isTrue);
      expect(anyBookReadInOneDay(progress), isTrue);
    });

    test('Obadiah read in one day counts', () {
      final progress = _wholeBook('Obadiah', [_at(2026, 7, 1)]);
      expect(anyBookReadInOneDay(progress), isTrue);
    });

    test('multi-chapter book fully read in one day counts', () {
      // Philippians has 4 chapters; all read on the same day.
      final chapters = bibleChapters['Philippians']!;
      final day = _at(2026, 7, 1);
      final progress = _wholeBook('Philippians', List.filled(chapters, day));
      expect(anyBookReadInOneDay(progress), isTrue);
    });

    test('a book read across two days does not count', () {
      final chapters = bibleChapters['Philippians']!;
      final readAts = [
        for (int c = 1; c <= chapters; c++)
          _at(2026, 7, c == chapters ? 2 : 1), // last chapter on the next day
      ];
      final progress = _wholeBook('Philippians', readAts);
      expect(bookReadInOneDay('Philippians', progress), isFalse);
      expect(anyBookReadInOneDay(progress), isFalse);
    });

    test('a partially-read book does not count', () {
      // Only chapter 1 of a multi-chapter book, all on one day.
      final progress = [_read('Philippians', 1, _at(2026, 7, 1))];
      expect(bookReadInOneDay('Philippians', progress), isFalse);
    });

    test('one single-day iteration counts even if another iteration spans days', () {
      final chapters = bibleChapters['Philippians']!;
      // Iteration 1: read across two days -> does not qualify on its own.
      final iter1 = _wholeBook(
        'Philippians',
        [for (int c = 1; c <= chapters; c++) _at(2026, 7, c == chapters ? 2 : 1)],
        iteration: 1,
      );
      // Iteration 2: read entirely on one day -> qualifies.
      final iter2 = _wholeBook(
        'Philippians',
        List.filled(chapters, _at(2026, 8, 1)),
        iteration: 2,
      );
      expect(bookReadInOneDay('Philippians', [...iter1, ...iter2]), isTrue);
    });
  });

  group('allShortBooksFinished (Short Book Reader)', () {
    Set<String> readSetForBooks(Iterable<String> books) {
      final set = <String>{};
      for (final book in books) {
        for (int c = 1; c <= bibleChapters[book]!; c++) {
          set.add('$book|$c');
        }
      }
      return set;
    }

    test('the five single-chapter books are the tracked set', () {
      expect(singleChapterBooks.toSet(),
          {'Obadiah', 'Philemon', '2 John', '3 John', 'Jude'});
      // Guard the definition: each must actually be one chapter.
      for (final book in singleChapterBooks) {
        expect(bibleChapters[book], 1, reason: '$book should be one chapter');
      }
    });

    test('no reading -> not earned', () {
      expect(allShortBooksFinished({}), isFalse);
    });

    test('all five single-chapter books read -> earned', () {
      expect(allShortBooksFinished(readSetForBooks(singleChapterBooks)), isTrue);
    });

    test('missing one short book -> not earned', () {
      final books = singleChapterBooks.where((b) => b != 'Jude');
      expect(allShortBooksFinished(readSetForBooks(books)), isFalse);
    });

    test('reading other books does not earn it', () {
      expect(allShortBooksFinished(readSetForBooks(['Philippians', 'Ruth'])),
          isFalse);
    });
  });
}
