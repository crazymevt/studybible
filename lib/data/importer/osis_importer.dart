import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:xml/xml.dart';

import '../content_store.dart';
import '../models/verse_segment.dart';

/// Maps OSIS book abbreviations to full canonical book names.
const Map<String, String> _osisBookNames = {
  // Old Testament
  'Gen': 'Genesis', 'Exod': 'Exodus', 'Lev': 'Leviticus', 'Num': 'Numbers',
  'Deut': 'Deuteronomy', 'Josh': 'Joshua', 'Judg': 'Judges', 'Ruth': 'Ruth',
  '1Sam': '1 Samuel', '2Sam': '2 Samuel', '1Kgs': '1 Kings', '2Kgs': '2 Kings',
  '1Chr': '1 Chronicles',
  '2Chr': '2 Chronicles',
  'Ezra': 'Ezra',
  'Neh': 'Nehemiah',
  'Esth': 'Esther', 'Job': 'Job', 'Ps': 'Psalms', 'Prov': 'Proverbs',
  'Eccl': 'Ecclesiastes',
  'Song': 'Song of Solomon',
  'Isa': 'Isaiah',
  'Jer': 'Jeremiah',
  'Lam': 'Lamentations', 'Ezek': 'Ezekiel', 'Dan': 'Daniel', 'Hos': 'Hosea',
  'Joel': 'Joel', 'Amos': 'Amos', 'Obad': 'Obadiah', 'Jonah': 'Jonah',
  'Mic': 'Micah', 'Nah': 'Nahum', 'Hab': 'Habakkuk', 'Zeph': 'Zephaniah',
  'Hag': 'Haggai', 'Zech': 'Zechariah', 'Mal': 'Malachi',
  // New Testament
  'Matt': 'Matthew', 'Mark': 'Mark', 'Luke': 'Luke', 'John': 'John',
  'Acts': 'Acts',
  'Rom': 'Romans',
  '1Cor': '1 Corinthians',
  '2Cor': '2 Corinthians',
  'Gal': 'Galatians',
  'Eph': 'Ephesians',
  'Phil': 'Philippians',
  'Col': 'Colossians',
  '1Thess': '1 Thessalonians', '2Thess': '2 Thessalonians',
  '1Tim': '1 Timothy',
  '2Tim': '2 Timothy',
  'Titus': 'Titus',
  'Phlm': 'Philemon',
  'Heb': 'Hebrews', 'Jas': 'James', '1Pet': '1 Peter', '2Pet': '2 Peter',
  '1John': '1 John',
  '2John': '2 John',
  '3John': '3 John',
  'Jude': 'Jude',
  'Rev': 'Revelation',
};

/// The NT book abbreviations for determining testament.
const Set<String> _ntBooks = {
  'Matt',
  'Mark',
  'Luke',
  'John',
  'Acts',
  'Rom',
  '1Cor',
  '2Cor',
  'Gal',
  'Eph',
  'Phil',
  'Col',
  '1Thess',
  '2Thess',
  '1Tim',
  '2Tim',
  'Titus',
  'Phlm',
  'Heb',
  'Jas',
  '1Pet',
  '2Pet',
  '1John',
  '2John',
  '3John',
  'Jude',
  'Rev',
};

class OsisImporter {
  final ContentStore store;

  OsisImporter(this.store);

  /// Import an OSIS XML file into the content store.
  ///
  /// [xmlFile] is the downloaded OSIS XML file.
  /// [versionId] is the short identifier (e.g. "KJV").
  /// [title] is the display name for this version.
  /// [language] is the language code (e.g. "en").
  Future<void> importOsisFile(
    File xmlFile,
    String versionId,
    String title,
    String language,
  ) async {
    final xmlString = await xmlFile.readAsString();
    final document = XmlDocument.parse(xmlString);

    // Extract title from header if available, falling back to the passed-in title
    String resolvedTitle = title;
    final workTitleElements = document.findAllElements('title');
    for (final el in workTitleElements) {
      // Get the first <title> inside <work>
      final parent = el.parent;
      if (parent is XmlElement && parent.localName == 'work') {
        final t = el.innerText.trim();
        if (t.isNotEmpty) {
          resolvedTitle = t;
        }
        break;
      }
    }

    // Insert version record
    final vid = versionId.toUpperCase();
    await store.deleteVersion(vid);

    await store
        .into(store.versions)
        .insert(
          VersionsCompanion.insert(
            id: versionId.toUpperCase(),
            abbreviation: versionId,
            name: resolvedTitle,
            language: Value(language),
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Find all book divs
    final bookDivs = document
        .findAllElements('div')
        .where(
          (el) =>
              el.getAttribute('type') == 'book' &&
              el.getAttribute('osisID') != null,
        )
        .toList();

    int bookOrder = 0;
    final Map<String, int> bookIdMap =
        {}; // osisBookAbbr -> inserted book row id

    for (final bookDiv in bookDivs) {
      final osisBookId = bookDiv.getAttribute('osisID')!;
      final bookName = _osisBookNames[osisBookId] ?? osisBookId;
      final testament = _ntBooks.contains(osisBookId) ? 'NT' : 'OT';

      bookOrder++;
      final insertedBookId = await store
          .into(store.books)
          .insert(
            BooksCompanion.insert(
              versionId: vid,
              name: bookName,
              bookOrder: bookOrder,
              testament: testament,
            ),
          );
      bookIdMap[osisBookId] = insertedBookId;
    }

    // Now batch-insert all verses. _extractBookVerses walks the book in
    // document order so it handles both container-form verses
    // (<verse>text</verse>) and milestone-form verses (<verse sID/> text
    // <verse eID/>), the latter being common in CrossWire/eBible OSIS.
    int verseCount = 0;
    await store.batch((batch) {
      for (final bookDiv in bookDivs) {
        final osisBookId = bookDiv.getAttribute('osisID')!;
        final bookId = bookIdMap[osisBookId];
        if (bookId == null) continue;

        for (final v in extractOsisBookVerses(bookDiv)) {
          batch.insert(
            store.verses,
            VersesCompanion.insert(
              bookId: bookId,
              chapter: v.chapter,
              verse: v.verse,
              textContent: v.text,
              segments: v.segmentsJson,
            ),
          );
          verseCount++;
        }
      }
    });

    if (verseCount == 0) {
      // Don't leave a books-but-no-verses shell behind; fail loudly instead.
      await store.deleteVersion(vid);
      throw Exception(
        'No verses found in OSIS file "$resolvedTitle" — its structure may be unsupported.',
      );
    }

    // Update FTS5 search index
    await store.customStatement(
      '''
      INSERT INTO content_search(type, reference_id, text_content) 
      SELECT 'verse', v.id, v.text_content 
      FROM verses v 
      JOIN books b ON v.book_id = b.id 
      WHERE b.version_id = ?
    ''',
      [vid],
    );
  }

}

/// Parse the chapter number from an osisID like "Gen.1".
int _parseChapterNum(String osisId) {
  final parts = osisId.split('.');
  if (parts.length >= 2) {
    return int.tryParse(parts[1]) ?? 1;
  }
  return 1;
}

/// Parse the verse number from an osisID like "Gen.1.1".
int _parseVerseNum(String osisId) {
  final parts = osisId.split('.');
  if (parts.length >= 3) {
    return int.tryParse(parts[2]) ?? 1;
  }
  return 1;
}

/// Extract every verse in [bookDiv] as ordered records, handling both OSIS
/// verse encodings: the container form, where a `verse` element wraps its text,
/// and the milestone form, where empty `verse` start/end markers (sID/eID)
/// bracket text that lives as siblings between them (common in CrossWire/eBible
/// OSIS).
///
/// The walk is a single document-order traversal that tracks the current
/// chapter/verse via `chapter`/`verse` markers (or container elements). Inline
/// markup (e.g. `w` tags) is flattened into the running text, while each `note`
/// becomes a footnote [VerseSegment] kept out of the plain text so it never
/// pollutes the search index.
List<OsisVerse> extractOsisBookVerses(XmlElement bookDiv) {
  final out = <OsisVerse>[];
  int chapter = 0;
  int? verse;
  final segments = <VerseSegment>[];
  final current = StringBuffer();
  final plain = StringBuffer();

  void flushText() {
    final collapsed = current.toString().replaceAll(RegExp(r'\s+'), ' ');
    current.clear();
    if (collapsed.trim().isEmpty) {
      // Preserve a separating space so adjacent words don't run together.
      if (collapsed.isNotEmpty) plain.write(' ');
      return;
    }
    segments.add(VerseSegment(text: collapsed));
    plain.write(collapsed);
  }

  void closeVerse() {
    if (verse == null) return;
    flushText();
    final text = plain.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isNotEmpty) {
      out.add(OsisVerse(
        chapter: chapter,
        verse: verse!,
        text: text,
        segmentsJson: jsonEncode(segments.map((s) => s.toJson()).toList()),
      ));
    }
    segments.clear();
    current.clear();
    plain.clear();
    verse = null;
  }

  void walk(XmlNode node) {
    for (final child in node.children) {
      if (child is XmlText) {
        if (verse != null) current.write(child.value);
      } else if (child is XmlElement) {
        final name = child.localName;
        if (name == 'chapter') {
          // Any chapter boundary closes an open verse. A start marker (or a
          // container chapter) updates the current chapter number; only a
          // container chapter (no sID) nests its verses, so recurse there.
          closeVerse();
          if (child.getAttribute('eID') == null) {
            final osisID = child.getAttribute('osisID');
            if (osisID != null) chapter = _parseChapterNum(osisID);
            if (child.getAttribute('sID') == null) walk(child);
          }
        } else if (name == 'verse') {
          final sID = child.getAttribute('sID');
          final eID = child.getAttribute('eID');
          final osisID = child.getAttribute('osisID');
          if (eID != null) {
            closeVerse();
          } else if (sID != null) {
            // Milestone start: text follows as siblings.
            closeVerse();
            if (osisID != null) verse = _parseVerseNum(osisID);
          } else {
            // Container verse: text is in this element's children.
            closeVerse();
            if (osisID != null) verse = _parseVerseNum(osisID);
            walk(child);
            closeVerse();
          }
        } else if (name == 'note') {
          if (verse != null) {
            flushText();
            final noteText =
                child.innerText.replaceAll(RegExp(r'\s+'), ' ').trim();
            if (noteText.isNotEmpty) {
              segments.add(
                VerseSegment(isFootnote: true, footnoteText: noteText),
              );
            }
          }
          // Don't recurse into note content — it isn't verse text.
        } else {
          // Inline wrappers (w, q, divineName, transChange, …): recurse so
          // their text joins the current verse.
          walk(child);
        }
      }
    }
  }

  walk(bookDiv);
  closeVerse(); // flush a trailing open verse at end of book
  return out;
}

class OsisVerse {
  final int chapter;
  final int verse;
  final String text;
  final String segmentsJson;

  OsisVerse({
    required this.chapter,
    required this.verse,
    required this.text,
    required this.segmentsJson,
  });
}
