import 'dart:convert';

/// The four Gospels, in canonical order, keyed by the short JSON field names
/// used in `assets/data/gospel_harmony.json`.
const Map<String, String> harmonyGospelBooks = {
  'mt': 'Matthew',
  'mk': 'Mark',
  'lk': 'Luke',
  'jn': 'John',
};

/// One Gospel's account of a harmony event: a verse range that may span a
/// chapter boundary (e.g. Mark 8:31–9:1).
class HarmonyRef {
  final String book;
  final int startChapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;

  const HarmonyRef({
    required this.book,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
  });

  /// "Mark 8:31–9:1", "Luke 15:1–32", or "John 18:1" for a single verse.
  String get label {
    final b = '$book $startChapter:$startVerse';
    if (startChapter == endChapter) {
      if (startVerse == endVerse) return b;
      return '$b–$endVerse';
    }
    return '$b–$endChapter:$endVerse';
  }

  /// Whether ([chapter], [verse]) falls inside this range. With [verse] null,
  /// matches any verse of a chapter the range touches.
  bool contains(String book, int chapter, [int? verse]) {
    if (book != this.book) return false;
    if (chapter < startChapter || chapter > endChapter) return false;
    if (verse == null) return true;
    if (chapter == startChapter && verse < startVerse) return false;
    if (chapter == endChapter && verse > endVerse) return false;
    return true;
  }
}

/// One event ("pericope") of the harmony, with the parallel account in each
/// Gospel that records it. [id] is the event's stable position in the file.
class HarmonyEvent {
  final int id;
  final String title;
  final String sectionTitle;

  /// The accounts, in canonical Gospel order. 1–4 entries.
  final List<HarmonyRef> refs;

  const HarmonyEvent({
    required this.id,
    required this.title,
    required this.sectionTitle,
    required this.refs,
  });

  HarmonyRef? refFor(String book) {
    for (final r in refs) {
      if (r.book == book) return r;
    }
    return null;
  }
}

class HarmonySection {
  final String title;
  final List<HarmonyEvent> events;

  const HarmonySection({required this.title, required this.events});
}

/// The full harmony of the Gospels: a chronologically ordered list of events,
/// each mapping to its parallel passages in Matthew, Mark, Luke, and John.
class GospelHarmony {
  final String attribution;
  final List<HarmonySection> sections;
  final List<HarmonyEvent> events;

  const GospelHarmony({
    required this.attribution,
    required this.sections,
    required this.events,
  });

  /// Parses the bundled `gospel_harmony.json` document.
  factory GospelHarmony.fromJsonString(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final sections = <HarmonySection>[];
    final events = <HarmonyEvent>[];
    var id = 0;
    for (final s in (data['sections'] as List)) {
      final section = s as Map<String, dynamic>;
      final sectionTitle = section['title'] as String;
      final sectionEvents = <HarmonyEvent>[];
      for (final e in (section['events'] as List)) {
        final event = e as Map<String, dynamic>;
        final refs = <HarmonyRef>[];
        for (final entry in harmonyGospelBooks.entries) {
          final range = event[entry.key] as List?;
          if (range == null) continue;
          refs.add(HarmonyRef(
            book: entry.value,
            startChapter: range[0] as int,
            startVerse: range[1] as int,
            endChapter: range[2] as int,
            endVerse: range[3] as int,
          ));
        }
        final ev = HarmonyEvent(
          id: id++,
          title: event['title'] as String,
          sectionTitle: sectionTitle,
          refs: refs,
        );
        sectionEvents.add(ev);
        events.add(ev);
      }
      sections.add(HarmonySection(title: sectionTitle, events: sectionEvents));
    }
    return GospelHarmony(
      attribution: (data['attribution'] as String?) ?? '',
      sections: sections,
      events: events,
    );
  }

  bool get isEmpty => events.isEmpty;

  HarmonyEvent? eventById(int id) =>
      (id >= 0 && id < events.length) ? events[id] : null;

  /// Whether [book] is one of the four Gospels this harmony covers.
  static bool isGospel(String book) => harmonyGospelBooks.containsValue(book);

  /// Reverse lookup: the events whose account in [book] touches [chapter]
  /// (and [verse], when given), in harmony order.
  List<HarmonyEvent> eventsFor(String book, int chapter, [int? verse]) {
    if (!isGospel(book)) return const [];
    return [
      for (final e in events)
        if (e.refs.any((r) => r.contains(book, chapter, verse))) e,
    ];
  }
}
