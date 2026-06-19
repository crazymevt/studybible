import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:xml/xml.dart';

import '../../data/content_store.dart';
import '../../data/models/verse_segment.dart';

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

    // Now batch-insert all verses
    await store.batch((batch) {
      for (final bookDiv in bookDivs) {
        final osisBookId = bookDiv.getAttribute('osisID')!;
        final bookId = bookIdMap[osisBookId];
        if (bookId == null) continue;

        final chapters = bookDiv.findElements('chapter');
        for (final chapterEl in chapters) {
          final chapterOsisId = chapterEl.getAttribute('osisID') ?? '';
          // osisID format: "Gen.1"
          final chapterNum = _parseChapterNum(chapterOsisId);

          final verses = chapterEl.findElements('verse');
          for (final verseEl in verses) {
            final verseOsisId = verseEl.getAttribute('osisID') ?? '';
            // osisID format: "Gen.1.1"
            final verseNum = _parseVerseNum(verseOsisId);

            final text = _extractVerseText(verseEl);
            if (text.isEmpty) continue;

            final segments = [VerseSegment(text: text)];
            final segmentsJson = jsonEncode(
              segments.map((s) => s.toJson()).toList(),
            );

            batch.insert(
              store.verses,
              VersesCompanion.insert(
                bookId: bookId,
                chapter: chapterNum,
                verse: verseNum,
                textContent: text,
                segments: segmentsJson,
              ),
            );
          }
        }
      }
    });

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

  /// Extract the plain text content from a verse element,
  /// stripping any nested XML markup.
  String _extractVerseText(XmlElement verseEl) {
    final buffer = StringBuffer();
    _collectText(verseEl, buffer);
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Recursively collect text nodes from an element.
  void _collectText(XmlNode node, StringBuffer buffer) {
    for (final child in node.children) {
      if (child is XmlText) {
        buffer.write(child.value);
      } else if (child is XmlElement) {
        _collectText(child, buffer);
      }
    }
  }
}
