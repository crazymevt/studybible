// Build-time converter: NavesTopicalDictionary.csv -> assets/data/naves_topical.json
//
// Source data: https://github.com/BradyStephenson/bible-data
// (NavesTopicalDictionary.csv), CC-BY-4.0. Nave's Topical Bible itself is
// public domain.
//
// Usage:
//   dart run tool/build_naves_topical.dart <input.csv> [output.json]
//
// The CSV columns are: section, subject, entry. `entry` is a multi-line block
// where each line is a subtopic: a description followed by scripture references
// in Nave's compact notation, e.g.
//   -Lineage of EXO 6:16-20; JOS 21:4,10; 1CH 6:2,3; 23:13
// Some lines are cross-topic pointers, e.g. `-See PRIEST, HIGH`.
//
// Output shape (compact):
//   {
//     "books": [ "Genesis", ... 66 names ... ],
//     "topics": [
//       { "t": "AARON", "s": "A",
//         "e": [ { "d": "Lineage of",
//                  "r": [ [bookIdx, chapter, verseOrNull, verseEndOrNull], ... ],
//                  "see": [ "PRIEST, HIGH" ] }, ... ] }
//     ]
//   }

import 'dart:convert';
import 'dart:io';

/// Canonical book order/names the app uses.
const List<String> kBooks = [
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua',
  'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings',
  '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job',
  'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon', 'Isaiah',
  'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
  'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai',
  'Zechariah', 'Malachi', 'Matthew', 'Mark', 'Luke', 'John', 'Acts',
  'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
  'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
  '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
  '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation',
];

/// Maps a Nave's book token (normalized: upper-cased, trailing '.' stripped)
/// to its index in [kBooks].
final Map<String, int> kBookCodes = () {
  final m = <String, int>{};
  void put(String code, String name) => m[code] = kBooks.indexOf(name);
  put('GEN', 'Genesis');
  put('EXO', 'Exodus');
  put('LEV', 'Leviticus');
  put('NUM', 'Numbers');
  put('DEU', 'Deuteronomy');
  put('JOS', 'Joshua');
  put('JDG', 'Judges');
  put('RUT', 'Ruth');
  put('1SA', '1 Samuel');
  put('2SA', '2 Samuel');
  put('1KI', '1 Kings');
  put('2KI', '2 Kings');
  put('1CH', '1 Chronicles');
  put('2CH', '2 Chronicles');
  put('EZR', 'Ezra');
  put('NEH', 'Nehemiah');
  put('EST', 'Esther');
  put('JOB', 'Job');
  put('PSA', 'Psalms');
  put('PRO', 'Proverbs');
  put('ECC', 'Ecclesiastes');
  put('SO', 'Song of Solomon'); // Nave's uses "So" for Song of Solomon
  put('ISA', 'Isaiah');
  put('JER', 'Jeremiah');
  put('LAM', 'Lamentations');
  put('EZK', 'Ezekiel');
  put('DAN', 'Daniel');
  put('HOS', 'Hosea');
  put('JOL', 'Joel');
  put('AMO', 'Amos');
  put('OBA', 'Obadiah');
  put('OBADIAH', 'Obadiah');
  put('JON', 'Jonah');
  put('MIC', 'Micah');
  put('NAM', 'Nahum');
  put('HAB', 'Habakkuk');
  put('ZEP', 'Zephaniah');
  put('HAG', 'Haggai');
  put('ZEC', 'Zechariah');
  put('MAL', 'Malachi');
  put('MAT', 'Matthew');
  put('MRK', 'Mark');
  put('LUK', 'Luke');
  put('JHN', 'John');
  put('ACT', 'Acts');
  put('ROM', 'Romans');
  put('1CO', '1 Corinthians');
  put('2CO', '2 Corinthians');
  put('GAL', 'Galatians');
  put('EPH', 'Ephesians');
  put('PHP', 'Philippians');
  put('COL', 'Colossians');
  put('1TH', '1 Thessalonians');
  put('2TH', '2 Thessalonians');
  put('1TI', '1 Timothy');
  put('2TI', '2 Timothy');
  put('TIT', 'Titus');
  put('PHM', 'Philemon');
  put('HEB', 'Hebrews');
  put('JAS', 'James');
  put('1PE', '1 Peter');
  put('2PE', '2 Peter');
  put('1JN', '1 John');
  put('1JHN', '1 John'); // variant
  put('2JN', '2 John');
  put('3JN', '3 John');
  put('JUDE', 'Jude');
  put('REV', 'Revelation');
  return m;
}();

/// Single-chapter books: a bare number after the code is a verse, not a chapter.
final Set<int> kSingleChapterBooks = {
  kBooks.indexOf('Obadiah'),
  kBooks.indexOf('Philemon'),
  kBooks.indexOf('2 John'),
  kBooks.indexOf('3 John'),
  kBooks.indexOf('Jude'),
};

int? _lookupBook(String token) {
  var t = token.toUpperCase();
  if (t.endsWith('.')) t = t.substring(0, t.length - 1);
  return kBookCodes[t];
}

/// Parse a reference run (everything after the description) into structured
/// refs. Maintains current book/chapter so continuations resolve correctly.
List<List<int?>> parseRefs(String run) {
  final refs = <List<int?>>[];
  // Collapse runs of whitespace (the data has occasional double spaces).
  final segments = run.split(';');
  int? currentBook;
  for (var seg in segments) {
    seg = seg.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (seg.isEmpty) continue;

    // Does this segment start with a book token?
    final spaceIdx = seg.indexOf(' ');
    if (spaceIdx > 0) {
      final firstToken = seg.substring(0, spaceIdx);
      final bookIdx = _lookupBook(firstToken);
      if (bookIdx != null) {
        currentBook = bookIdx;
        seg = seg.substring(spaceIdx + 1).trim();
      }
    }
    if (currentBook == null) continue; // ref without an established book

    if (seg.contains(':')) {
      final colon = seg.indexOf(':');
      final chapter = int.tryParse(seg.substring(0, colon).trim());
      if (chapter == null) continue;
      final verseList = seg.substring(colon + 1).trim();
      for (final piece in verseList.split(',')) {
        final p = piece.trim();
        if (p.isEmpty) continue;
        final dash = p.indexOf('-');
        if (dash > 0) {
          final start = int.tryParse(p.substring(0, dash).trim());
          final end = int.tryParse(p.substring(dash + 1).trim());
          if (start != null) refs.add([currentBook, chapter, start, end]);
        } else {
          final v = int.tryParse(p);
          if (v != null) refs.add([currentBook, chapter, v, null]);
        }
      }
    } else {
      // No colon: a bare number. Whole chapter, unless single-chapter book
      // (then it's a verse in chapter 1).
      final n = int.tryParse(seg.replaceAll(RegExp(r'[^0-9].*$'), ''));
      if (n == null) continue;
      if (kSingleChapterBooks.contains(currentBook)) {
        refs.add([currentBook, 1, n, null]);
      } else {
        refs.add([currentBook, n, null, null]);
      }
    }
  }
  return refs;
}

/// Find where the reference run begins in a subtopic line: the first book token
/// followed by whitespace and a digit. Returns the index, or -1 if none.
int _refStart(String line) {
  // Lookahead for the digit so a numbered book code (e.g. "2KI") preceded by
  // prose ("Damascus 2KI 5:12") isn't split — without it, "Damascus 2" matches
  // first and consumes the "2", orphaning "KI".
  final re = RegExp(r"\b([0-9]?[A-Za-z][A-Za-z'.]*)\s+(?=[0-9])");
  for (final m in re.allMatches(line)) {
    if (_lookupBook(m.group(1)!) != null) return m.start;
  }
  return -1;
}

Map<String, dynamic> parseEntry(String entry) {
  // Split the entry block into subtopic lines (each begins with '-'). Lines that
  // don't begin with '-' are continuations of the previous subtopic.
  final rawLines = entry.split('\n');
  final subtopics = <String>[];
  for (final raw in rawLines) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) continue;
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('-')) {
      subtopics.add(trimmed.substring(1).trim());
    } else if (subtopics.isNotEmpty) {
      subtopics[subtopics.length - 1] =
          '${subtopics.last} ${trimmed.trim()}'.trim();
    } else {
      subtopics.add(trimmed.trim());
    }
  }

  final entries = <Map<String, dynamic>>[];
  for (final raw in subtopics) {
    // Strip the source's internal link anchors (e.g. "[260]ANGER OF GOD").
    final sub = raw.replaceAll(RegExp(r'\[\d+\]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final see = <String>[];
    // "See OTHER TOPIC" cross-references.
    final seeMatch = RegExp(r'^See +(.+)$', caseSensitive: false).firstMatch(sub);
    if (seeMatch != null) {
      final target = seeMatch
          .group(1)!
          .replaceFirst(RegExp(r'^also +', caseSensitive: false), '')
          .replaceAll(RegExp(r',?\s*which see\.?$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[."]+$'), '')
          .trim();
      if (target.isNotEmpty) see.add(target);
      entries.add({'d': sub, 'r': <List<int?>>[], 'see': see});
      continue;
    }
    final start = _refStart(sub);
    if (start < 0) {
      entries.add({'d': sub, 'r': <List<int?>>[], 'see': see});
    } else {
      final desc = sub.substring(0, start).trim();
      final refs = parseRefs(sub.substring(start));
      entries.add({'d': desc, 'r': refs, 'see': see});
    }
  }
  return {'e': entries};
}

/// Minimal RFC4180 CSV parser (handles quoted fields with newlines and ""
/// escaping). Returns rows of fields.
List<List<String>> parseCsv(String input) {
  final rows = <List<String>>[];
  var field = StringBuffer();
  var row = <String>[];
  var inQuotes = false;
  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else {
      if (c == '"') {
        inQuotes = true;
      } else if (c == ',') {
        row.add(field.toString());
        field = StringBuffer();
      } else if (c == '\n') {
        row.add(field.toString());
        rows.add(row);
        row = <String>[];
        field = StringBuffer();
      } else if (c == '\r') {
        // skip
      } else {
        field.write(c);
      }
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/build_naves_topical.dart <input.csv> [output.json]');
    exit(64);
  }
  final inputPath = args[0];
  final outputPath = args.length > 1 ? args[1] : 'assets/data/naves_topical.json';

  // Sanity: every canonical book must be resolvable and indices valid.
  if (kBooks.length != 66) {
    stderr.writeln('ERROR: expected 66 books, got ${kBooks.length}');
    exit(1);
  }

  var raw = File(inputPath).readAsStringSync();
  if (raw.isNotEmpty && raw.codeUnitAt(0) == 0xFEFF) raw = raw.substring(1); // BOM
  final rows = parseCsv(raw);

  final topics = <Map<String, dynamic>>[];
  var totalRefs = 0;
  var topicsWithNoRefs = 0;
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    if (r.length < 3) continue;
    final section = r[0].trim();
    final subject = r[1].trim();
    final entry = r[2];
    if (subject.isEmpty) continue;
    final parsed = parseEntry(entry);
    final entries = parsed['e'] as List;
    var refCount = 0;
    for (final e in entries) {
      refCount += (e['r'] as List).length;
    }
    totalRefs += refCount;
    if (refCount == 0) topicsWithNoRefs++;
    topics.add({'t': subject, 's': section, 'e': entries});
  }

  final out = {'books': kBooks, 'topics': topics};
  final outFile = File(outputPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(jsonEncode(out));

  stderr.writeln('Topics: ${topics.length}');
  stderr.writeln('Total refs: $totalRefs');
  stderr.writeln('Topics with no refs: $topicsWithNoRefs');
  stderr.writeln('Output: $outputPath (${(outFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB)');
}
