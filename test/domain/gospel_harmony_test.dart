import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/harmony/gospel_harmony.dart';

const _fixture = '''
{
  "attribution": "Test attribution",
  "sections": [
    {
      "title": "Section One",
      "events": [
        {"title": "All four", "mt": [14, 13, 14, 21], "mk": [6, 30, 6, 44], "lk": [9, 10, 9, 17], "jn": [6, 1, 6, 15]},
        {"title": "Cross-chapter", "mk": [8, 31, 9, 1]}
      ]
    },
    {
      "title": "Section Two",
      "events": [
        {"title": "Luke only", "lk": [15, 1, 15, 32]}
      ]
    }
  ]
}
''';

void main() {
  final harmony = GospelHarmony.fromJsonString(_fixture);

  test('parses sections, events, and refs in canonical Gospel order', () {
    expect(harmony.attribution, 'Test attribution');
    expect(harmony.sections, hasLength(2));
    expect(harmony.events, hasLength(3));

    final feeding = harmony.events[0];
    expect(feeding.title, 'All four');
    expect(feeding.sectionTitle, 'Section One');
    expect(feeding.refs.map((r) => r.book),
        ['Matthew', 'Mark', 'Luke', 'John']);
    expect(feeding.refFor('Mark')!.startVerse, 30);
    expect(feeding.refFor('John')!.label, 'John 6:1–15');
  });

  test('event ids are stable positions usable with eventById', () {
    for (final e in harmony.events) {
      expect(harmony.eventById(e.id), same(e));
    }
    expect(harmony.eventById(-1), isNull);
    expect(harmony.eventById(99), isNull);
  });

  test('labels collapse single verses and span chapters', () {
    expect(harmony.events[1].refs.single.label, 'Mark 8:31–9:1');
    const single = HarmonyRef(
        book: 'John', startChapter: 18, startVerse: 1, endChapter: 18, endVerse: 1);
    expect(single.label, 'John 18:1');
  });

  group('HarmonyRef.contains', () {
    const range = HarmonyRef(
        book: 'Mark', startChapter: 8, startVerse: 31, endChapter: 9, endVerse: 1);

    test('inside, boundary, and outside verses', () {
      expect(range.contains('Mark', 8, 31), isTrue);
      expect(range.contains('Mark', 8, 38), isTrue);
      expect(range.contains('Mark', 9, 1), isTrue);
      expect(range.contains('Mark', 8, 30), isFalse);
      expect(range.contains('Mark', 9, 2), isFalse);
      expect(range.contains('Luke', 8, 31), isFalse);
    });

    test('chapter-only queries match any chapter the range touches', () {
      expect(range.contains('Mark', 8), isTrue);
      expect(range.contains('Mark', 9), isTrue);
      expect(range.contains('Mark', 7), isFalse);
      expect(range.contains('Mark', 10), isFalse);
    });
  });

  group('eventsFor reverse lookup', () {
    test('finds every event touching a verse, in harmony order', () {
      final hits = harmony.eventsFor('Mark', 8, 31);
      expect(hits.map((e) => e.title), ['Cross-chapter']);
      expect(harmony.eventsFor('Luke', 15, 11).map((e) => e.title),
          ['Luke only']);
    });

    test('chapter-only lookup and non-Gospel books', () {
      expect(harmony.eventsFor('Mark', 6).map((e) => e.title), ['All four']);
      expect(harmony.eventsFor('Acts', 6), isEmpty);
      expect(GospelHarmony.isGospel('Acts'), isFalse);
      expect(GospelHarmony.isGospel('John'), isTrue);
    });
  });
}
