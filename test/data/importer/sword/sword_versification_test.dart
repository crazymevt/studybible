import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/importer/sword/sword_versification.dart';

/// The KJV canon is the high-risk data in the whole SWORD effort: a single
/// wrong verse count silently shifts every later verse. These tests pin it
/// against the well-known aggregate totals plus famous spot values, so any
/// transcription slip surfaces immediately.
void main() {
  final kjv = kjvVersification;

  int sumBooks(List<SwordVersifiedBook> books) =>
      books.fold(0, (a, b) => a + b.verseCount);
  int sumChapters(List<SwordVersifiedBook> books) =>
      books.fold(0, (a, b) => a + b.chapterCount);

  group('KJV versification — checksums', () {
    test('book counts', () {
      expect(kjv.ot, hasLength(39));
      expect(kjv.nt, hasLength(27));
    });

    test('chapter totals', () {
      expect(sumChapters(kjv.ot), 929);
      expect(sumChapters(kjv.nt), 260);
      expect(sumChapters(kjv.ot) + sumChapters(kjv.nt), 1189);
    });

    test('verse totals match the canonical KJV aggregate', () {
      expect(sumBooks(kjv.ot), 23145);
      expect(sumBooks(kjv.nt), 7957);
      expect(sumBooks(kjv.ot) + sumBooks(kjv.nt), 31102);
    });
  });

  group('KJV versification — spot checks', () {
    SwordVersifiedBook book(String osis) =>
        [...kjv.ot, ...kjv.nt].firstWhere((b) => b.osis == osis);

    test('famous chapter/verse counts', () {
      expect(book('Gen').chapterCount, 50);
      expect(book('Gen').verseCount, 1533);
      expect(book('Ps').chapterCount, 150);
      expect(book('Ps').verseCount, 2461);
      expect(book('Ps').versesPerChapter[118], 176); // Psalm 119
      expect(book('Ps').versesPerChapter[116], 2); // Psalm 117 (shortest)
      expect(book('Lam').versesPerChapter[2], 66); // Lamentations 3
      expect(book('Obad').versesPerChapter, [21]);
      expect(book('John').chapterCount, 21);
      expect(book('3John').versesPerChapter, [14]);
      expect(book('Rev').chapterCount, 22);
      expect(book('Rev').versesPerChapter.last, 21); // Revelation 22
      expect(book('Matt').verseCount, 1071);
    });
  });

  group('SwordVersification.indexOf', () {
    test('first verses sit at index 4 (after the two intro + title + chapter '
        'heading slots)', () {
      // Slots 0–1 = module/testament headings, 2 = book title, 3 = ch.1 heading.
      // Verified against the real CrossWire KJV module (Gen 1:1 at slot 4).
      expect(kjv.indexOf('OT', 0, 1, 1), 4); // Genesis 1:1
      expect(kjv.indexOf('NT', 0, 1, 1), 4); // Matthew 1:1 (NT-relative)
    });

    test('walks within a chapter and across chapters', () {
      expect(kjv.indexOf('OT', 0, 1, 31), 34); // Genesis 1:31 (last of ch.1)
      expect(kjv.indexOf('OT', 0, 2, 1), 36); // Genesis 2:1 (past ch.2 heading)
    });

    test('crosses book boundaries using the full book span', () {
      // Genesis span = 1 (title) + 50 (chapter headings) + 1533 verses = 1584.
      // Exodus title follows at 2 + 1584 = 1586, Exodus 1:1 at 1588.
      expect(kjv.indexOf('OT', 1, 1, 1), 1588);
    });

    test('reverse-consistent with recordCount (last verse is count-1)', () {
      // The final OT verse is Malachi 4:6 (book 38). Its index must be exactly
      // one below the testament record count.
      final mal = kjv.ot.last;
      final lastIdx =
          kjv.indexOf('OT', kjv.ot.length - 1, mal.chapterCount,
              mal.versesPerChapter.last);
      expect(lastIdx, kjv.recordCount('OT') - 1);
    });

    test('returns null for out-of-range coordinates', () {
      expect(kjv.indexOf('OT', 0, 1, 32), isNull); // Genesis 1 only has 31
      expect(kjv.indexOf('OT', 0, 51, 1), isNull); // Genesis only has 50 ch
      expect(kjv.indexOf('OT', -1, 1, 1), isNull);
      expect(kjv.indexOf('NT', 99, 1, 1), isNull);
      expect(kjv.indexOf('OT', 0, 1, 0), isNull); // verse < 1
    });
  });

  group('swordVersificationByName', () {
    test('resolves KJV case-insensitively', () {
      expect(swordVersificationByName('KJV'), same(kjv));
      expect(swordVersificationByName('kjv'), same(kjv));
    });

    test('returns null for unsupported schemes', () {
      expect(swordVersificationByName('Synodal'), isNull);
      expect(swordVersificationByName('LXX'), isNull);
    });
  });
}
