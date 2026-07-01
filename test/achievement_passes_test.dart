import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/highlight_palette.dart';
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

  group('usedEveryHighlightColor (Full Palette)', () {
    final allHexes = [for (final s in highlightPalette) s.hex];

    test('no highlights -> not earned', () {
      expect(usedEveryHighlightColor(const []), isFalse);
    });

    test('every palette colour used -> earned', () {
      // Regression: the old check required 5 distinct colours but the palette
      // only offers 4, so "Full Palette" was impossible to earn.
      expect(usedEveryHighlightColor(allHexes), isTrue);
    });

    test('missing one colour -> not earned', () {
      expect(usedEveryHighlightColor(allHexes.skip(1)), isFalse);
    });

    test('normalises case and stray "#" so real stored hexes still count', () {
      final messy = [
        for (final hex in allHexes) hex.replaceAll('#', '').toLowerCase(),
      ];
      expect(usedEveryHighlightColor(messy), isTrue);
    });

    test('duplicates and off-palette colours do not stand in for a colour', () {
      final missingLast = [
        ...allHexes.take(allHexes.length - 1),
        allHexes.first, // duplicate
        '#123456', // off-palette
      ];
      expect(usedEveryHighlightColor(missingLast), isFalse);
    });

    test('legacy (pre-revision) hexes still count toward the achievement', () {
      // Highlights made before the green/blue swatches were revised keep their
      // original stored hex; they must still map onto the new palette colours.
      const legacyEveryColour = ['#FBE083', '#98E2C6', '#B5E2FA', '#F4A8C4'];
      expect(usedEveryHighlightColor(legacyEveryColour), isTrue);
    });
  });

  group('canonicalHighlightHex', () {
    test('maps superseded green and blue to their replacements', () {
      expect(canonicalHighlightHex('#98E2C6'), '#A3E29A');
      expect(canonicalHighlightHex('#B5E2FA'), '#A9C7F5');
    });

    test('maps regardless of case or leading "#"', () {
      expect(canonicalHighlightHex('98e2c6'), '#A3E29A');
    });

    test('leaves current and unknown hexes unchanged', () {
      expect(canonicalHighlightHex('#A3E29A'), '#A3E29A');
      expect(canonicalHighlightHex('#FBE083'), '#FBE083');
      expect(canonicalHighlightHex('#123456'), '#123456');
    });
  });

  group('chapterReadForCurrentPass', () {
    test('unread chapter is not read for the current pass', () {
      expect(chapterReadForCurrentPass('John', 3, {}), isFalse);
    });

    test('read once (mid first pass) is read for the current pass', () {
      // No full pass completed yet, so a single read is ahead of 0 passes.
      expect(chapterReadForCurrentPass('John', 3, {'John_3': 1}), isTrue);
    });

    test('after a full pass, every chapter becomes markable again', () {
      // Whole Bible read once -> 1 completed pass. A chapter still at count 1
      // is no longer ahead of the completed passes, so it is markable again.
      final counts = _wholeBibleReadCounts(1);
      expect(chapterReadForCurrentPass('John', 3, counts), isFalse);
    });

    test('re-reading a chapter within the same pass locks it again', () {
      // Whole Bible once, then John 3 read a second time -> its count (2) is
      // ahead of the single completed pass, so it is read for this pass.
      final counts = _wholeBibleReadCounts(1);
      counts['John_3'] = 2;
      expect(chapterReadForCurrentPass('John', 3, counts), isTrue);
    });

    test('non-canonical book: read after a single read', () {
      expect(chapterReadForCurrentPass('Tobit', 1, {}), isFalse);
      expect(chapterReadForCurrentPass('Tobit', 1, {'Tobit_1': 1}), isTrue);
    });
  });
}
