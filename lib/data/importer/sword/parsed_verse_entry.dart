import '../../models/verse_segment.dart';

/// The plain text and rich segments parsed out of a single verse's source
/// markup, regardless of which SWORD `SourceType` it came from (OSIS, GBF,
/// ThML, or plaintext). Produced by the per-source fragment parsers and
/// consumed by `SwordBibleImporter`.
class ParsedVerseEntry {
  /// Markup-free verse text, whitespace collapsed — suitable for the search
  /// index and for `verses.textContent`.
  final String text;

  /// Rich segments (Strong's numbers, added/italic words, footnotes) for
  /// `verses.segments`.
  final List<VerseSegment> segments;

  const ParsedVerseEntry(this.text, this.segments);
}
