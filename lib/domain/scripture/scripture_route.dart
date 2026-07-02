/// One stop on a sermon's scripture route: a reference (optionally a range)
/// the reader navigates to and temporarily highlights while the route is
/// active. Pure data — books are carried by name so this stays independent of
/// the data layer.
class ScriptureRouteStop {
  final String bookName;
  final int chapter;

  /// Null for a chapter-only reference ("Psalms 23"), in which case the whole
  /// chapter is highlighted.
  final int? verse;

  /// End of a range ("Rom 8:28-30", "Gen 1:1-2:3"). When [endChapter] is set
  /// without [endVerse] the range is whole chapters ("Isaiah 9-10").
  final int? endChapter;
  final int? endVerse;

  const ScriptureRouteStop({
    required this.bookName,
    required this.chapter,
    this.verse,
    this.endChapter,
    this.endVerse,
  });

  /// Human-readable reference, e.g. "John 3:16–18" or "Genesis 1:1–2:3".
  String get label {
    final buffer = StringBuffer('$bookName $chapter');
    if (verse != null) buffer.write(':$verse');
    if (endChapter != null) {
      if (endChapter != chapter) {
        buffer.write('–$endChapter');
        if (endVerse != null) buffer.write(':$endVerse');
      } else if (endVerse != null && endVerse != verse) {
        buffer.write('–$endVerse');
      }
    }
    return buffer.toString();
  }

  /// Whether this stop's range touches ([bookName], [chapter]).
  bool coversChapter(String bookName, int chapter) {
    if (bookName != this.bookName) return false;
    final last = endChapter ?? this.chapter;
    return chapter >= this.chapter && chapter <= last;
  }

  @override
  bool operator ==(Object other) =>
      other is ScriptureRouteStop &&
      other.bookName == bookName &&
      other.chapter == chapter &&
      other.verse == verse &&
      other.endChapter == endChapter &&
      other.endVerse == endVerse;

  @override
  int get hashCode => Object.hash(bookName, chapter, verse, endChapter, endVerse);

  @override
  String toString() => 'ScriptureRouteStop($label)';
}

/// The verse numbers of chapter ([bookName], [chapter]) that [stop] covers,
/// picked from [chapterVerses] (the verse numbers actually present in the
/// displayed chapter). Empty when the stop doesn't touch this chapter.
///
/// A chapter-only stop covers the whole chapter; a cross-chapter range covers
/// from its start verse to the end of the first chapter, every verse of the
/// chapters in between, and up to its end verse in the last.
Set<int> stopHighlightVerses(
  ScriptureRouteStop stop,
  String bookName,
  int chapter,
  Iterable<int> chapterVerses,
) {
  if (!stop.coversChapter(bookName, chapter)) return const <int>{};
  // Chapter-level reference (single chapter or chapter range without verses).
  if (stop.verse == null) return chapterVerses.toSet();

  final lastChapter = stop.endChapter ?? stop.chapter;
  final from = chapter == stop.chapter ? stop.verse! : 1;
  final int? to = chapter == lastChapter ? (stop.endVerse ?? stop.verse) : null;
  return chapterVerses.where((v) => v >= from && (to == null || v <= to)).toSet();
}

/// Collapses immediate repeats of the same reference (a sermon often cites the
/// passage it is expounding several times in a row) while keeping deliberate
/// returns to an earlier passage later in the route.
List<ScriptureRouteStop> dedupeConsecutiveStops(List<ScriptureRouteStop> stops) {
  final result = <ScriptureRouteStop>[];
  for (final stop in stops) {
    if (result.isEmpty || result.last != stop) result.add(stop);
  }
  return result;
}
