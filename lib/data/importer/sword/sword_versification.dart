/// SWORD versification tables and the positional verse-index math.
///
/// SWORD's binary verse drivers (`zText`/`RawText`, `.bzv`/`.vss` files) do not
/// store book/chapter/verse coordinates per record. Instead each record sits at
/// a fixed *position* derived from the module's versification scheme, and the
/// reader must compute that position to find a verse. This file provides the
/// ordered canon (per-chapter verse counts) for a scheme plus [indexOf], which
/// turns a (testament, book, chapter, verse) coordinate into the 0-based record
/// index used to seek the index file.
///
/// ## Index layout
///
/// Each testament has its own index file (`ot.*` / `nt.*`) whose records are
/// laid out as:
///
/// ```
/// 0: module heading
/// 1: testament heading
/// 2: book 0 heading (title)
/// 3: book 0, chapter 1 heading
/// 4: book 0, chapter 1, verse 1
/// ...
/// ```
///
/// i.e. the testament contributes two leading "heading" slots, every book one
/// heading slot, and every chapter one heading slot, before its verses. Getting
/// these heading slots right is the whole game — an off-by-one shifts every
/// subsequent verse. The arithmetic in [indexOf] mirrors SWORD's
/// `VersificationMgr::getOffsetFromVerse`.
///
/// Pure Dart, no IO — the binary file reading lives in the zText reader.
library;

/// One book in a versification scheme: its identity plus the verse count of
/// each chapter ([versesPerChapter] is 0-indexed by chapter-1).
class SwordVersifiedBook {
  /// OSIS abbreviation, e.g. `Gen`, `1Sam`, `Rev`. Matches the codes used by
  /// the OSIS importer so book identity is shared across importers.
  final String osis;

  /// Canonical display name, e.g. `Genesis`, `1 Samuel`, `Revelation`.
  final String name;

  /// Verse count for each chapter, indexed by chapter-1.
  final List<int> versesPerChapter;

  const SwordVersifiedBook(this.osis, this.name, this.versesPerChapter);

  int get chapterCount => versesPerChapter.length;

  /// Total verses across all chapters.
  int get verseCount {
    var total = 0;
    for (final n in versesPerChapter) {
      total += n;
    }
    return total;
  }
}

/// A complete versification scheme (e.g. KJV), split into Old and New Testament
/// book lists in canonical order.
class SwordVersification {
  /// Scheme name as it appears in a module's `Versification` conf key.
  final String name;
  final List<SwordVersifiedBook> ot;
  final List<SwordVersifiedBook> nt;

  const SwordVersification({
    required this.name,
    required this.ot,
    required this.nt,
  });

  /// The book list for [testament] (`'NT'` → New Testament, anything else →
  /// Old Testament).
  List<SwordVersifiedBook> booksFor(String testament) =>
      testament == 'NT' ? nt : ot;

  /// The 0-based record index of ([testament] [bookIndex]:[chapter]:[verse])
  /// within that testament's index file, accounting for the testament/book/
  /// chapter heading slots. [bookIndex] is the book's 0-based position within
  /// the testament. Returns null if the coordinate is out of range for this
  /// scheme.
  ///
  /// Mirrors the running layout: index 0 is the testament heading, then each
  /// book contributes `1 + chapterCount + verseCount` slots.
  int? indexOf(String testament, int bookIndex, int chapter, int verse) {
    final books = booksFor(testament);
    if (bookIndex < 0 || bookIndex >= books.length) return null;
    final book = books[bookIndex];
    if (chapter < 1 || chapter > book.chapterCount) return null;
    if (verse < 1 || verse > book.versesPerChapter[chapter - 1]) return null;

    // SWORD reserves TWO leading slots before the first book — the module
    // heading (0) and the testament heading (1), both normally empty — so the
    // first book's title sits at index 2. Verified against real CrossWire
    // modules (Genesis title at slot 2, "CHAPTER 1." at 3, Gen 1:1 at 4) and
    // matching pysword's BibleStructure, whose book offsets also start at 2.
    var idx = 2;
    for (var b = 0; b < bookIndex; b++) {
      idx += 1 + books[b].chapterCount + books[b].verseCount;
    }
    // Step past this book's heading, then over every prior chapter (its own
    // heading slot plus its verses). We now sit on `chapter`'s heading slot;
    // adding the (1-based) verse lands on the verse itself.
    idx += 1;
    for (var c = 1; c < chapter; c++) {
      idx += 1 + book.versesPerChapter[c - 1];
    }
    idx += verse;
    return idx;
  }

  /// The total number of index records in [testament], i.e. one past the last
  /// valid index. Equals the testament heading plus every book's span.
  int recordCount(String testament) {
    var total = 2; // module + testament heading slots (see indexOf)
    for (final b in booksFor(testament)) {
      total += 1 + b.chapterCount + b.verseCount;
    }
    return total;
  }
}

/// Look up a built-in versification scheme by its conf name (case-insensitive).
/// Currently only KJV is shipped; returns null for unknown/unsupported schemes
/// so callers can reject the module with a clear message.
SwordVersification? swordVersificationByName(String name) {
  if (name.toLowerCase() == 'kjv') return kjvVersification;
  return null;
}

/// The KJV versification — SWORD's default and by far the most common scheme.
/// Verse counts are the standard KJV canon (validated in tests against the
/// well-known aggregate totals: 23,145 OT + 7,957 NT = 31,102 verses).
final SwordVersification kjvVersification = SwordVersification(
  name: 'KJV',
  ot: const [
    SwordVersifiedBook('Gen', 'Genesis', [
      31, 25, 24, 26, 32, 22, 24, 22, 29, 32, 32, 20, 18, 24, 21, 16, 27, 33, //
      38, 18, 34, 24, 20, 67, 34, 35, 46, 22, 35, 43, 55, 32, 20, 31, 29, 43, //
      36, 30, 23, 23, 57, 38, 34, 34, 28, 34, 31, 22, 33, 26 //
    ]),
    SwordVersifiedBook('Exod', 'Exodus', [
      22, 25, 22, 31, 23, 30, 25, 32, 35, 29, 10, 51, 22, 31, 27, 36, 16, 27, //
      25, 26, 36, 31, 33, 18, 40, 37, 21, 43, 46, 38, 18, 35, 23, 35, 35, 38, //
      29, 31, 43, 38 //
    ]),
    SwordVersifiedBook('Lev', 'Leviticus', [
      17, 16, 17, 35, 19, 30, 38, 36, 24, 20, 47, 8, 59, 57, 33, 34, 16, 30, //
      37, 27, 24, 33, 44, 23, 55, 46, 34 //
    ]),
    SwordVersifiedBook('Num', 'Numbers', [
      54, 34, 51, 49, 31, 27, 89, 26, 23, 36, 35, 16, 33, 45, 41, 50, 13, 32, //
      22, 29, 35, 41, 30, 25, 18, 65, 23, 31, 40, 16, 54, 42, 56, 29, 34, 13 //
    ]),
    SwordVersifiedBook('Deut', 'Deuteronomy', [
      46, 37, 29, 49, 33, 25, 26, 20, 29, 22, 32, 32, 18, 29, 23, 22, 20, 22, //
      21, 20, 23, 30, 25, 22, 19, 19, 26, 68, 29, 20, 30, 52, 29, 12 //
    ]),
    SwordVersifiedBook('Josh', 'Joshua', [
      18, 24, 17, 24, 15, 27, 26, 35, 27, 43, 23, 24, 33, 15, 63, 10, 18, 28, //
      51, 9, 45, 34, 16, 33 //
    ]),
    SwordVersifiedBook('Judg', 'Judges', [
      36, 23, 31, 24, 31, 40, 25, 35, 57, 18, 40, 15, 25, 20, 20, 31, 13, 31, //
      30, 48, 25 //
    ]),
    SwordVersifiedBook('Ruth', 'Ruth', [22, 23, 18, 22]),
    SwordVersifiedBook('1Sam', '1 Samuel', [
      28, 36, 21, 22, 12, 21, 17, 22, 27, 27, 15, 25, 23, 52, 35, 23, 58, 30, //
      24, 42, 15, 23, 29, 22, 44, 25, 12, 25, 11, 31, 13 //
    ]),
    SwordVersifiedBook('2Sam', '2 Samuel', [
      27, 32, 39, 12, 25, 23, 29, 18, 13, 19, 27, 31, 39, 33, 37, 23, 29, 33, //
      43, 26, 22, 51, 39, 25 //
    ]),
    SwordVersifiedBook('1Kgs', '1 Kings', [
      53, 46, 28, 34, 18, 38, 51, 66, 28, 29, 43, 33, 34, 31, 34, 34, 24, 46, //
      21, 43, 29, 53 //
    ]),
    SwordVersifiedBook('2Kgs', '2 Kings', [
      18, 25, 27, 44, 27, 33, 20, 29, 37, 36, 21, 21, 25, 29, 38, 20, 41, 37, //
      37, 21, 26, 20, 37, 20, 30 //
    ]),
    SwordVersifiedBook('1Chr', '1 Chronicles', [
      54, 55, 24, 43, 26, 81, 40, 40, 44, 14, 47, 40, 14, 17, 29, 43, 27, 17, //
      19, 8, 30, 19, 32, 31, 31, 32, 34, 21, 30 //
    ]),
    SwordVersifiedBook('2Chr', '2 Chronicles', [
      17, 18, 17, 22, 14, 42, 22, 18, 31, 19, 23, 16, 22, 15, 19, 14, 19, 34, //
      11, 37, 20, 12, 21, 27, 28, 23, 9, 27, 36, 27, 21, 33, 25, 33, 27, 23 //
    ]),
    SwordVersifiedBook('Ezra', 'Ezra', [
      11, 70, 13, 24, 17, 22, 28, 36, 15, 44 //
    ]),
    SwordVersifiedBook('Neh', 'Nehemiah', [
      11, 20, 32, 23, 19, 19, 73, 18, 38, 39, 36, 47, 31 //
    ]),
    SwordVersifiedBook('Esth', 'Esther', [
      22, 23, 15, 17, 14, 14, 10, 17, 32, 3 //
    ]),
    SwordVersifiedBook('Job', 'Job', [
      22, 13, 26, 21, 27, 30, 21, 22, 35, 22, 20, 25, 28, 22, 35, 22, 16, 21, //
      29, 29, 34, 30, 17, 25, 6, 14, 23, 28, 25, 31, 40, 22, 33, 37, 16, 33, //
      24, 41, 30, 24, 34, 17 //
    ]),
    SwordVersifiedBook('Ps', 'Psalms', [
      6, 12, 8, 8, 12, 10, 17, 9, 20, 18, 7, 8, 6, 7, 5, 11, 15, 50, 14, 9, //
      13, 31, 6, 10, 22, 12, 14, 9, 11, 12, 24, 11, 22, 22, 28, 12, 40, 22, //
      13, 17, 13, 11, 5, 26, 17, 11, 9, 14, 20, 23, 19, 9, 6, 7, 23, 13, 11, //
      11, 17, 12, 8, 12, 11, 10, 13, 20, 7, 35, 36, 5, 24, 20, 28, 23, 10, //
      12, 20, 72, 13, 19, 16, 8, 18, 12, 13, 17, 7, 18, 52, 17, 16, 15, 5, //
      23, 11, 13, 12, 9, 9, 5, 8, 28, 22, 35, 45, 48, 43, 13, 31, 7, 10, 10, //
      9, 8, 18, 19, 2, 29, 176, 7, 8, 9, 4, 8, 5, 6, 5, 6, 8, 8, 3, 18, 3, 3, //
      21, 26, 9, 8, 24, 13, 10, 7, 12, 15, 21, 10, 20, 14, 9, 6 //
    ]),
    SwordVersifiedBook('Prov', 'Proverbs', [
      33, 22, 35, 27, 23, 35, 27, 36, 18, 32, 31, 28, 25, 35, 33, 33, 28, 24, //
      29, 30, 31, 29, 35, 34, 28, 28, 27, 28, 27, 33, 31 //
    ]),
    SwordVersifiedBook('Eccl', 'Ecclesiastes', [
      18, 26, 22, 16, 20, 12, 29, 17, 18, 20, 10, 14 //
    ]),
    SwordVersifiedBook('Song', 'Song of Solomon', [
      17, 17, 11, 16, 16, 13, 13, 14 //
    ]),
    SwordVersifiedBook('Isa', 'Isaiah', [
      31, 22, 26, 6, 30, 13, 25, 22, 21, 34, 16, 6, 22, 32, 9, 14, 14, 7, 25, //
      6, 17, 25, 18, 23, 12, 21, 13, 29, 24, 33, 9, 20, 24, 17, 10, 22, 38, //
      22, 8, 31, 29, 25, 28, 28, 25, 13, 15, 22, 26, 11, 23, 15, 12, 17, 13, //
      12, 21, 14, 21, 22, 11, 12, 19, 12, 25, 24 //
    ]),
    SwordVersifiedBook('Jer', 'Jeremiah', [
      19, 37, 25, 31, 31, 30, 34, 22, 26, 25, 23, 17, 27, 22, 21, 21, 27, 23, //
      15, 18, 14, 30, 40, 10, 38, 24, 22, 17, 32, 24, 40, 44, 26, 22, 19, 32, //
      21, 28, 18, 16, 18, 22, 13, 30, 5, 28, 7, 47, 39, 46, 64, 34 //
    ]),
    SwordVersifiedBook('Lam', 'Lamentations', [
      22, 22, 66, 22, 22 //
    ]),
    SwordVersifiedBook('Ezek', 'Ezekiel', [
      28, 10, 27, 17, 17, 14, 27, 18, 11, 22, 25, 28, 23, 23, 8, 63, 24, 32, //
      14, 49, 32, 31, 49, 27, 17, 21, 36, 26, 21, 26, 18, 32, 33, 31, 15, 38, //
      28, 23, 29, 49, 26, 20, 27, 31, 25, 24, 23, 35 //
    ]),
    SwordVersifiedBook('Dan', 'Daniel', [
      21, 49, 30, 37, 31, 28, 28, 27, 27, 21, 45, 13 //
    ]),
    SwordVersifiedBook('Hos', 'Hosea', [
      11, 23, 5, 19, 15, 11, 16, 14, 17, 15, 12, 14, 16, 9 //
    ]),
    SwordVersifiedBook('Joel', 'Joel', [20, 32, 21]),
    SwordVersifiedBook('Amos', 'Amos', [
      15, 16, 15, 13, 27, 14, 17, 14, 15 //
    ]),
    SwordVersifiedBook('Obad', 'Obadiah', [21]),
    SwordVersifiedBook('Jonah', 'Jonah', [17, 10, 10, 11]),
    SwordVersifiedBook('Mic', 'Micah', [16, 13, 12, 13, 15, 16, 20]),
    SwordVersifiedBook('Nah', 'Nahum', [15, 13, 19]),
    SwordVersifiedBook('Hab', 'Habakkuk', [17, 20, 19]),
    SwordVersifiedBook('Zeph', 'Zephaniah', [18, 15, 20]),
    SwordVersifiedBook('Hag', 'Haggai', [15, 23]),
    SwordVersifiedBook('Zech', 'Zechariah', [
      21, 13, 10, 14, 11, 15, 14, 23, 17, 12, 17, 14, 9, 21 //
    ]),
    SwordVersifiedBook('Mal', 'Malachi', [14, 17, 18, 6]),
  ],
  nt: const [
    SwordVersifiedBook('Matt', 'Matthew', [
      25, 23, 17, 25, 48, 34, 29, 34, 38, 42, 30, 50, 58, 36, 39, 28, 27, 35, //
      30, 34, 46, 46, 39, 51, 46, 75, 66, 20 //
    ]),
    SwordVersifiedBook('Mark', 'Mark', [
      45, 28, 35, 41, 43, 56, 37, 38, 50, 52, 33, 44, 37, 72, 47, 20 //
    ]),
    SwordVersifiedBook('Luke', 'Luke', [
      80, 52, 38, 44, 39, 49, 50, 56, 62, 42, 54, 59, 35, 35, 32, 31, 37, 43, //
      48, 47, 38, 71, 56, 53 //
    ]),
    SwordVersifiedBook('John', 'John', [
      51, 25, 36, 54, 47, 71, 53, 59, 41, 42, 57, 50, 38, 31, 27, 33, 26, 40, //
      42, 31, 25 //
    ]),
    SwordVersifiedBook('Acts', 'Acts', [
      26, 47, 26, 37, 42, 15, 60, 40, 43, 48, 30, 25, 52, 28, 41, 40, 34, 28, //
      41, 38, 40, 30, 35, 27, 27, 32, 44, 31 //
    ]),
    SwordVersifiedBook('Rom', 'Romans', [
      32, 29, 31, 25, 21, 23, 25, 39, 33, 21, 36, 21, 14, 23, 33, 27 //
    ]),
    SwordVersifiedBook('1Cor', '1 Corinthians', [
      31, 16, 23, 21, 13, 20, 40, 13, 27, 33, 34, 31, 13, 40, 58, 24 //
    ]),
    SwordVersifiedBook('2Cor', '2 Corinthians', [
      24, 17, 18, 18, 21, 18, 16, 24, 15, 18, 33, 21, 14 //
    ]),
    SwordVersifiedBook('Gal', 'Galatians', [24, 21, 29, 31, 26, 18]),
    SwordVersifiedBook('Eph', 'Ephesians', [23, 22, 21, 32, 33, 24]),
    SwordVersifiedBook('Phil', 'Philippians', [30, 30, 21, 23]),
    SwordVersifiedBook('Col', 'Colossians', [29, 23, 25, 18]),
    SwordVersifiedBook('1Thess', '1 Thessalonians', [10, 20, 13, 18, 28]),
    SwordVersifiedBook('2Thess', '2 Thessalonians', [12, 17, 18]),
    SwordVersifiedBook('1Tim', '1 Timothy', [20, 15, 16, 16, 25, 21]),
    SwordVersifiedBook('2Tim', '2 Timothy', [18, 26, 17, 22]),
    SwordVersifiedBook('Titus', 'Titus', [16, 15, 15]),
    SwordVersifiedBook('Phlm', 'Philemon', [25]),
    SwordVersifiedBook('Heb', 'Hebrews', [
      14, 18, 19, 16, 14, 20, 28, 13, 28, 39, 40, 29, 25 //
    ]),
    SwordVersifiedBook('Jas', 'James', [27, 26, 18, 17, 20]),
    SwordVersifiedBook('1Pet', '1 Peter', [25, 25, 22, 19, 14]),
    SwordVersifiedBook('2Pet', '2 Peter', [21, 22, 18]),
    SwordVersifiedBook('1John', '1 John', [10, 29, 24, 21, 21]),
    SwordVersifiedBook('2John', '2 John', [13]),
    SwordVersifiedBook('3John', '3 John', [14]),
    SwordVersifiedBook('Jude', 'Jude', [25]),
    SwordVersifiedBook('Rev', 'Revelation', [
      20, 29, 22, 11, 14, 17, 17, 13, 21, 11, 19, 17, 18, 20, 8, 21, 18, 24, //
      21, 15, 27, 21 //
    ]),
  ],
);
