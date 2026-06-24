import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/achievement_service.dart';

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
}
