import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/domain/search/reference_parser.dart';

/// A Bible reference found embedded in free text (a sermon or journal body),
/// with its character span into the scanned string and the resolved [book].
///
/// [start] is inclusive, [end] exclusive — so `text.substring(start, end)` is
/// the matched reference text. Offsets are into the exact string passed to
/// [BibleReferenceScanner.scan]; for a Quill document that is
/// `document.toPlainText()`, whose offsets line up with the document's own
/// offsets for plain-text runs.
class ReferenceMatch {
  final int start;
  final int end;
  final Book book;
  final int chapter;
  final int? verse;

  /// End of a range, when the reference spans more than one verse/chapter
  /// (e.g. "Rom 8:28-30" or "Gen 1:1-2:3"). Navigation only uses the start,
  /// but the range is captured so the span covers the whole citation.
  final int? endChapter;
  final int? endVerse;

  const ReferenceMatch({
    required this.start,
    required this.end,
    required this.book,
    required this.chapter,
    this.verse,
    this.endChapter,
    this.endVerse,
  });
}

/// Scans free prose for Bible references and resolves each to a [Book].
///
/// Unlike the anchored [ReferenceParser.parse] (which matches a whole query
/// string), this finds references *embedded* in text so they can be turned
/// into tappable links.
///
/// False positives are the main risk in prose ("Mark 5 boxes", "at 3:15",
/// "1 or 2 things"). Two guards keep them down:
///  1. The book token must begin with a capital letter and resolve via
///     [ReferenceParser.findBook] — plain numbers and lowercase words never
///     match.
///  2. Callers that want maximum precision pass `requireVerse: true`, which
///     drops chapter-only hits ("Mark 5") and keeps only verse-bearing ones
///     ("Mark 5:3"). The auto-linker uses this so ordinary sentences that
///     happen to contain a book name aren't rewritten.
class BibleReferenceScanner {
  // Group 1: book token — an optional leading 1/2/3 (numbered books like
  //          "1 John"), then 1–3 capitalized words, allowing a lowercase "of"
  //          ("Song of Solomon"). Preceded by a non-alphanumeric boundary so
  //          "aJohn" / "11John" don't match.
  // Group 2: chapter. Group 3: verse (optional).
  // Groups 4/5: end of a range (optional) — "-30" or "-2:3".
  static final RegExp _regex = RegExp(
    r'(?<![A-Za-z0-9])'
    r'((?:[123]\s?)?[A-Z][a-zA-Z]+(?:\s+(?:of\s+)?[A-Z][a-zA-Z]+){0,2})'
    r'\s+(\d{1,3})'
    r'(?:\s*:\s*(\d{1,3}))?'
    r'(?:\s*[-–]\s*(\d{1,3})(?:\s*:\s*(\d{1,3}))?)?',
  );

  /// Returns every reference found in [text], resolved against [books], in the
  /// order they appear. When [requireVerse] is true, chapter-only references
  /// are skipped (see the class doc).
  static List<ReferenceMatch> scan(
    String text,
    List<Book> books, {
    bool requireVerse = false,
  }) {
    if (books.isEmpty) return const [];
    final results = <ReferenceMatch>[];

    // Anchored scan rather than `allMatches`: the book token is greedy and can
    // grab a capitalized word or leading digit that actually belongs to the
    // *next* reference ("Compare John 3:16", "See 1 Cor 13:4"). We only skip
    // past a match once its book resolves; on a non-book candidate we step
    // forward a single character so the swallowed word/digit is reconsidered.
    var i = 0;
    while (i < text.length) {
      final m = _regex.matchAsPrefix(text, i);
      if (m == null) {
        i++;
        continue;
      }
      final book = ReferenceParser.findBook(
        m.group(1)!.trim().toLowerCase(),
        books,
      );
      if (book == null) {
        i++;
        continue;
      }

      final chapter = int.parse(m.group(2)!);
      final verse = m.group(3) == null ? null : int.parse(m.group(3)!);
      if (requireVerse && verse == null) {
        // A real book, but chapter-only and the caller wants precision. Skip
        // past it rather than re-matching from inside it.
        i = m.end;
        continue;
      }

      int? endChapter;
      int? endVerse;
      final rangeA = m.group(4);
      final rangeB = m.group(5);
      if (rangeA != null) {
        if (rangeB != null) {
          // "1:1-2:3" — chapter:verse on both sides.
          endChapter = int.parse(rangeA);
          endVerse = int.parse(rangeB);
        } else if (verse != null) {
          // "8:28-30" — same chapter, ending verse.
          endChapter = chapter;
          endVerse = int.parse(rangeA);
        } else {
          // "9-10" — chapter range, no verses.
          endChapter = int.parse(rangeA);
        }
      }

      results.add(ReferenceMatch(
        start: m.start,
        end: m.end,
        book: book,
        chapter: chapter,
        verse: verse,
        endChapter: endChapter,
        endVerse: endVerse,
      ));
      i = m.end;
    }
    return results;
  }
}
