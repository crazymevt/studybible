import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/harmony/gospel_harmony.dart';

/// Sanity checks over the real bundled harmony dataset, so a bad edit to the
/// asset (swapped range ends, out-of-bounds chapter, empty section) fails CI
/// instead of surfacing as a broken panel.
void main() {
  const chapterCounts = {
    'Matthew': 28,
    'Mark': 16,
    'Luke': 24,
    'John': 21,
  };

  late GospelHarmony harmony;

  setUpAll(() {
    final raw =
        File('assets/data/gospel_harmony.json').readAsStringSync();
    harmony = GospelHarmony.fromJsonString(raw);
  });

  test('has an attribution and a substantial event list', () {
    expect(harmony.attribution, contains('Robertson'));
    expect(harmony.sections, isNotEmpty);
    expect(harmony.events.length, greaterThan(100));
  });

  test('every section and event is non-empty', () {
    for (final s in harmony.sections) {
      expect(s.title, isNotEmpty);
      expect(s.events, isNotEmpty, reason: 'section "${s.title}" is empty');
    }
    for (final e in harmony.events) {
      expect(e.title, isNotEmpty);
      expect(e.refs, isNotEmpty, reason: 'event "${e.title}" has no refs');
    }
  });

  test('every ref is a well-ordered range within its book', () {
    for (final e in harmony.events) {
      for (final r in e.refs) {
        final maxChapter = chapterCounts[r.book];
        expect(maxChapter, isNotNull,
            reason: '"${e.title}": unknown book ${r.book}');
        expect(r.startChapter, inInclusiveRange(1, maxChapter!),
            reason: '"${e.title}": ${r.label}');
        expect(r.endChapter, inInclusiveRange(r.startChapter, maxChapter),
            reason: '"${e.title}": ${r.label}');
        expect(r.startVerse, greaterThanOrEqualTo(1),
            reason: '"${e.title}": ${r.label}');
        expect(r.endVerse, greaterThanOrEqualTo(1),
            reason: '"${e.title}": ${r.label}');
        if (r.startChapter == r.endChapter) {
          expect(r.endVerse, greaterThanOrEqualTo(r.startVerse),
              reason: '"${e.title}": ${r.label}');
        }
      }
    }
  });

  test('the feeding of the five thousand appears in all four Gospels', () {
    final hits = harmony.eventsFor('John', 6, 10);
    final feeding =
        hits.where((e) => e.refs.length == 4).toList();
    expect(feeding, hasLength(1));
    expect(feeding.single.refFor('Matthew')!.startChapter, 14);
    expect(feeding.single.refFor('Mark')!.startChapter, 6);
    expect(feeding.single.refFor('Luke')!.startChapter, 9);
  });
}
