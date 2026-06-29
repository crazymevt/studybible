import 'dart:io';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:drift/drift.dart';
import '../content_store.dart';
import '../content_manager_api.dart';
import 'mybible_verse_parser.dart';
import '../models/verse_segment.dart';
import '../mybible_book_map.dart';

class MyBibleImporter {
  final ContentStore store;

  MyBibleImporter(this.store);

  String? _extractAbout(Database db) {
    final hasInfo = db.select("SELECT name FROM sqlite_master WHERE type='table' AND name='info'").isNotEmpty;
    if (!hasInfo) return null;
    
    final infoRows = db.select("SELECT name, value FROM info");
    if (infoRows.isEmpty) return null;
    
    String? detailedInfo;
    String? origin;
    String? description;
    
    for (final row in infoRows) {
      final name = row['name']?.toString() ?? '';
      final valueRaw = row['value']?.toString() ?? '';
      if (name.isEmpty || valueRaw.isEmpty) continue;
      
      final nameLower = name.toLowerCase();
      
      if (nameLower == 'detailed_info' || nameLower == 'origin' || nameLower == 'description') {
        // Strip HTML using html parser
        final document = html_parser.parse(valueRaw);
        final value = document.body?.text ?? valueRaw.replaceAll(RegExp(r'<[^>]*>'), '');
        
        if (nameLower == 'detailed_info') {
          detailedInfo = value;
        } else if (nameLower == 'origin') {
          origin = value;
        } else if (nameLower == 'description') {
          description = value;
        }
      }
    }
    
    final buffer = StringBuffer();
    if (detailedInfo != null) {
      buffer.writeln('detailed_info:\n$detailedInfo\n');
    }
    
    if (description != null) {
      buffer.writeln('description:\n$description\n');
    }
    
    if (origin != null) {
      buffer.writeln('origin:\n$origin\n');
    }
    
    return buffer.isEmpty ? null : buffer.toString().trim();
  }

  Future<void> importModuleFile(
    File sqliteFile,
    Ph4Module module,
    ModuleType inferredType,
  ) async {
    switch (inferredType) {
      case ModuleType.bible:
        await _importBible(sqliteFile, module);
        break;
      case ModuleType.subheadings:
        await _importSubheadings(sqliteFile, module);
        break;
      case ModuleType.commentary:
        await _importCommentary(sqliteFile, module);
        break;
      case ModuleType.dictionary:
        await _importDictionary(sqliteFile, module);
        break;
      case ModuleType.devotional:
        await _importDevotional(sqliteFile, module);
        break;
    }
  }

  Future<void> _importBible(File sqliteFile, Ph4Module module) async {
    final db = sqlite3.open(sqliteFile.path);

    try {
      String language = 'en';
      final hasInfo = db
          .select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='info'",
          )
          .isNotEmpty;
      if (hasInfo) {
        final infoRows = db.select(
          "SELECT value FROM info WHERE name='language'",
        );
        if (infoRows.isNotEmpty) {
          language = infoRows.first['value']?.toString() ?? 'en';
        }
      }

      String? about = _extractAbout(db);

      final versionId = module.abbr.toUpperCase();
      await store.deleteVersion(versionId);

      await store
          .into(store.versions)
          .insert(
            VersionsCompanion.insert(
              id: versionId,
              abbreviation: module.abbr,
              name: module.title,
              language: Value(language),
              about: Value(about),
            ),
            mode: InsertMode.insertOrReplace,
          );

      final Map<int, int> bookIdMap = {};
      final booksQuery = db.select(
        'SELECT * FROM books ORDER BY book_number',
      );

      for (final row in booksQuery) {
        if (row['book_number'] == null) continue;
        final bookNumber = num.parse(row['book_number'].toString()).toInt();

        final isNT = bookNumber >= 470;

        final insertedBookId = await store
            .into(store.books)
            .insert(
              BooksCompanion.insert(
                versionId: versionId,
                name: _bookNumberToName(bookNumber),
                bookOrder: bookNumber,
                testament: isNT ? 'NT' : 'OT',
              ),
            );

        bookIdMap[bookNumber] = insertedBookId;
      }

      // Cross-reference modules (e.g. the AV "KJV with cross references") ship a
      // companion `<base>.commentaries.SQLite3` whose `marker` column ("[1]",
      // "[2]"…) maps back to the `<f>[N]</f>` markers in the verse text. Without
      // it those markers carry no readable content. Resolve them here so the
      // footnote body is the actual cross-reference list.
      final crossRefs = _loadCrossRefMarkers(sqliteFile);

      final versesQuery = db.select(
        'SELECT book_number, chapter, verse, text FROM verses ORDER BY book_number, chapter, verse',
      );

      await store.batch((batch) {
        for (final row in versesQuery) {
          if (row['book_number'] == null ||
              row['chapter'] == null ||
              row['verse'] == null) {
            continue;
          }
          final bookNumber = num.parse(row['book_number'].toString()).toInt();
          final chapter = num.parse(row['chapter'].toString()).toInt();
          final verse = num.parse(row['verse'].toString()).toInt();
          final text = row['text']?.toString() ?? '';

          final bookId = bookIdMap[bookNumber];
          if (bookId == null) continue;

          // Fresh parser per verse: its tag-state fields aren't reset between
          // calls, so a verse with an unclosed tag would otherwise bleed
          // formatting into the next.
          var segments = MyBibleVerseParser().parseVerse(text);
          if (crossRefs.isNotEmpty) {
            segments = [
              for (final s in segments)
                _resolveFootnote(s, crossRefs, bookNumber, chapter, verse),
            ];
          }
          final segmentsJson = jsonEncode(
            segments.map((s) => s.toJson()).toList(),
          );

          batch.insert(
            store.verses,
            VersesCompanion.insert(
              bookId: bookId,
              chapter: chapter,
              verse: verse,
              textContent: text,
              segments: segmentsJson,
            ),
          );
        }
      });

      // Import subheadings if available
      final hasStories = db
          .select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='stories'",
          )
          .isNotEmpty;

      if (hasStories) {
        final storiesQuery = db.select(
          'SELECT * FROM stories ORDER BY book_number, chapter, verse',
        );

        await store.batch((batch) {
          for (final row in storiesQuery) {
            if (row['book_number'] == null ||
                row['chapter'] == null ||
                row['verse'] == null) {
              continue;
            }

            final bookNumber = num.parse(row['book_number'].toString()).toInt();
            final chapter = num.parse(row['chapter'].toString()).toInt();
            final verse = num.parse(row['verse'].toString()).toInt();
            final orderIfSeveral = row['order_if_several'] != null
                ? num.parse(row['order_if_several'].toString()).toInt()
                : 0;
            final title = row['title']?.toString() ?? '';

            if (title.isNotEmpty) {
              batch.insert(
                store.subheadings,
                SubheadingsCompanion.insert(
                  versionId: versionId,
                  bookOrder: bookNumber,
                  chapter: chapter,
                  verse: verse,
                  orderIfSeveral: Value(orderIfSeveral),
                  textContent: title,
                ),
              );
            }
          }
        });
      }

      // Update FTS5 index for this version. text_content keeps the raw MyBible
      // markup for the reader, but indexing it verbatim interleaves Strong's
      // numbers and tag fragments between words (FTS5 splits on '<' and '/'),
      // which breaks phrase search and pollutes the vocab. Strip the markup
      // with the verse parser first — mirroring the OSIS importer, which
      // already indexes cleaned text.
      final insertedVerses = await (store.select(store.verses)
            ..where((v) => v.bookId.isIn(bookIdMap.values.toList())))
          .get();

      final indexRows = <(int, String)>[];
      for (final v in insertedVerses) {
        final clean = mybibleVersePlainText(v.textContent);
        if (clean.isNotEmpty) indexRows.add((v.id, clean));
      }

      await store.transaction(() async {
        const chunkSize = 300;
        for (var i = 0; i < indexRows.length; i += chunkSize) {
          final end = (i + chunkSize) < indexRows.length
              ? i + chunkSize
              : indexRows.length;
          final chunk = indexRows.sublist(i, end);
          final values = List.filled(chunk.length, "('verse', ?, ?)").join(', ');
          final args = <Object?>[];
          for (final (id, clean) in chunk) {
            args.add(id);
            args.add(clean);
          }
          await store.customStatement(
            'INSERT INTO content_search(type, reference_id, text_content) VALUES $values',
            args,
          );
        }
      });
    } finally {
      db.close();
    }
  }

  Future<void> _importSubheadings(File sqliteFile, Ph4Module module) async {
    final db = sqlite3.open(sqliteFile.path);

    try {
      final versionId = module.abbr.toUpperCase();
      await store.deleteVersion(versionId);
      
      String? about = _extractAbout(db);

      await store
          .into(store.versions)
          .insert(
            VersionsCompanion.insert(
              id: versionId,
              abbreviation: module.abbr,
              name: module.title,
              language: const Value('en'),
              about: Value(about),
            ),
            mode: InsertMode.insertOrReplace,
          );

      final hasStories = db
          .select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='stories'",
          )
          .isNotEmpty;

      final hasSubheadings = db
          .select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='subheadings'",
          )
          .isNotEmpty;

      if (hasStories) {
        final storiesQuery = db.select(
          'SELECT * FROM stories ORDER BY book_number, chapter, verse',
        );

        await store.batch((batch) {
          for (final row in storiesQuery) {
            if (row['book_number'] == null ||
                row['chapter'] == null ||
                row['verse'] == null) {
              continue;
            }

            final bookNumber = num.parse(row['book_number'].toString()).toInt();
            final chapter = num.parse(row['chapter'].toString()).toInt();
            final verse = num.parse(row['verse'].toString()).toInt();
            final orderIfSeveral = row['order_if_several'] != null
                ? num.parse(row['order_if_several'].toString()).toInt()
                : 0;
            final title = row['title']?.toString() ?? '';

            if (title.isNotEmpty) {
              batch.insert(
                store.subheadings,
                SubheadingsCompanion.insert(
                  versionId: versionId,
                  bookOrder: bookNumber,
                  chapter: chapter,
                  verse: verse,
                  orderIfSeveral: Value(orderIfSeveral),
                  textContent: title,
                ),
              );
            }
          }
        });
      } else if (hasSubheadings) {
        final subheadingsQuery = db.select(
          'SELECT book_number, chapter, verse, subheading FROM subheadings ORDER BY book_number, chapter, verse',
        );

        await store.batch((batch) {
          for (final row in subheadingsQuery) {
            if (row['book_number'] == null ||
                row['chapter'] == null ||
                row['verse'] == null) {
              continue;
            }

            final bookNumber = num.parse(row['book_number'].toString()).toInt();
            final chapter = num.parse(row['chapter'].toString()).toInt();
            final verse = num.parse(row['verse'].toString()).toInt();
            final title = row['subheading']?.toString() ?? '';

            if (title.isNotEmpty) {
              batch.insert(
                store.subheadings,
                SubheadingsCompanion.insert(
                  versionId: versionId,
                  bookOrder: bookNumber,
                  chapter: chapter,
                  verse: verse,
                  orderIfSeveral: const Value(0),
                  textContent: title,
                ),
              );
            }
          }
        });
      }
    } finally {
      db.close();
    }
  }

  Future<void> _importCommentary(File sqliteFile, Ph4Module module) async {
    final db = sqlite3.open(sqliteFile.path);

    try {
      final existing = await (store.select(store.commentaries)..where((c) => c.abbreviation.equals(module.abbr))).get();
      for (final e in existing) {
        await store.deleteCommentary(e.id);
      }
      
      String? about = _extractAbout(db);

      final commentaryId = await store
          .into(store.commentaries)
          .insert(
            CommentariesCompanion.insert(
              abbreviation: module.abbr,
              name: module.title,
              about: Value(about),
            ),
          );

      final entriesQuery = db.select(
        'SELECT book_number, chapter_number_from, verse_number_from, text FROM commentaries ORDER BY book_number, chapter_number_from, verse_number_from',
      );

      await store.batch((batch) {
        for (final row in entriesQuery) {
          if (row['book_number'] == null) continue;
          final bookNumber = num.parse(row['book_number'].toString()).toInt();
          final chapter = row['chapter_number_from'] != null
              ? num.parse(row['chapter_number_from'].toString()).toInt()
              : null;
          final verse = row['verse_number_from'] != null
              ? num.parse(row['verse_number_from'].toString()).toInt()
              : null;
          final text = row['text']?.toString() ?? '';

          batch.insert(
            store.commentaryEntries,
            CommentaryEntriesCompanion.insert(
              commentaryId: commentaryId,
              bookName: _bookNumberToName(bookNumber),
              chapter: Value(chapter),
              verse: Value(verse),
              textContent: text,
            ),
          );
        }
      });

      // Update FTS5 index for this commentary (HTML content: strip markup).
      await store.indexStrippedEntries(
        'commentary',
        'commentary_entries',
        'commentary_id',
        commentaryId,
      );
    } finally {
      db.close();
    }
  }

  Future<void> _importDictionary(File sqliteFile, Ph4Module module) async {
    final db = sqlite3.open(sqliteFile.path);

    try {
      final existing = await (store.select(store.dictionaries)..where((d) => d.abbreviation.equals(module.abbr))).get();
      for (final e in existing) {
        await store.deleteDictionary(e.id);
      }
      
      String? about = _extractAbout(db);

      final dictionaryId = await store
          .into(store.dictionaries)
          .insert(
            DictionariesCompanion.insert(
              abbreviation: module.abbr,
              name: module.title,
              about: Value(about),
            ),
          );

      final entriesQuery = db.select(
        'SELECT topic, definition FROM dictionary ORDER BY topic',
      );

      await store.batch((batch) {
        for (final row in entriesQuery) {
          final word = row['topic']?.toString() ?? '';
          final definition = row['definition']?.toString() ?? '';

          batch.insert(
            store.dictionaryEntries,
            DictionaryEntriesCompanion.insert(
              dictionaryId: dictionaryId,
              word: word,
              definition: definition,
            ),
          );
        }
      });

      // Update FTS5 index for this dictionary
      await store.customStatement(
        '''
        INSERT INTO content_search(type, reference_id, text_content)
        SELECT 'dictionary', id, word
        FROM dictionary_entries
        WHERE dictionary_id = ?
      ''',
        [dictionaryId],
      );
    } finally {
      db.close();
    }
  }

  Future<void> _importDevotional(File sqliteFile, Ph4Module module) async {
    final db = sqlite3.open(sqliteFile.path);

    try {
      final existing = await (store.select(store.devotionals)..where((d) => d.abbreviation.equals(module.abbr))).get();
      for (final e in existing) {
        await store.deleteDevotional(e.id);
      }
      
      String? about = _extractAbout(db);

      final devotionalId = await store
          .into(store.devotionals)
          .insert(
            DevotionalsCompanion.insert(
              abbreviation: module.abbr,
              name: module.title,
              about: Value(about),
            ),
          );

      final entriesQuery = db.select(
        'SELECT day, devotion FROM devotions ORDER BY day',
      );

      await store.batch((batch) {
        for (final row in entriesQuery) {
          final day = row['day'] != null ? num.parse(row['day'].toString()).toInt() : 0;
          final devotion = row['devotion']?.toString() ?? '';

          batch.insert(
            store.devotionalEntries,
            DevotionalEntriesCompanion.insert(
              devotionalId: devotionalId,
              day: day,
              textContent: devotion,
            ),
          );
        }
      });

      // Update FTS5 index for this devotional (HTML content: strip markup).
      await store.indexStrippedEntries(
        'devotional',
        'devotional_entries',
        'devotional_id',
        devotionalId,
      );
    } finally {
      db.close();
    }
  }

  String _bookNumberToName(int number) {
    return mybibleBookMap[number] ?? 'Book $number';
  }

  /// Replaces a footnote segment's marker (e.g. "[1]") with the resolved
  /// cross-reference text from the companion commentaries module, when one is
  /// found for this verse. Non-footnote segments and unmatched markers pass
  /// through unchanged.
  VerseSegment _resolveFootnote(
    VerseSegment seg,
    Map<String, String> crossRefs,
    int bookNumber,
    int chapter,
    int verse,
  ) {
    if (!seg.isFootnote) return seg;
    final marker = seg.footnoteText?.trim();
    if (marker == null || marker.isEmpty) return seg;
    final resolved = crossRefs['$bookNumber:$chapter:$verse:$marker'];
    if (resolved == null || resolved.isEmpty) return seg;
    return VerseSegment(isFootnote: true, footnoteText: resolved);
  }

  /// Builds a `(book:chapter:verse:marker) -> text` lookup from a Bible
  /// module's companion `<base>.commentaries.SQLite3`, when it exists and has a
  /// `marker` column. Returns an empty map for ordinary modules (no companion,
  /// or a markerless commentary), so callers can no-op cheaply.
  Map<String, String> _loadCrossRefMarkers(File bibleFile) {
    final stem = p
        .basename(bibleFile.path)
        .replaceAll(RegExp(r'\.sqlite3?$', caseSensitive: false), '');
    final wanted = '${stem.toLowerCase()}.commentaries.sqlite3';

    File? companion;
    for (final entity in bibleFile.parent.listSync()) {
      if (entity is File &&
          p.basename(entity.path).toLowerCase() == wanted) {
        companion = entity;
        break;
      }
    }
    if (companion == null) return const {};

    final db = sqlite3.open(companion.path);
    try {
      final hasTable = db
          .select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='commentaries'",
          )
          .isNotEmpty;
      if (!hasTable) return const {};

      final hasMarker = db
          .select('PRAGMA table_info(commentaries)')
          .any((r) => r['name']?.toString().toLowerCase() == 'marker');
      if (!hasMarker) return const {};

      final rows = db.select(
        "SELECT book_number, chapter_number_from, verse_number_from, marker, text "
        "FROM commentaries WHERE marker IS NOT NULL AND marker != ''",
      );

      final map = <String, String>{};
      for (final row in rows) {
        if (row['book_number'] == null ||
            row['chapter_number_from'] == null ||
            row['verse_number_from'] == null) {
          continue;
        }
        final book = num.parse(row['book_number'].toString()).toInt();
        final chapter = num.parse(row['chapter_number_from'].toString()).toInt();
        final verse = num.parse(row['verse_number_from'].toString()).toInt();
        final marker = row['marker'].toString().trim();
        final text = renderMyBibleCrossRef(row['text']?.toString() ?? '');
        if (marker.isEmpty || text.isEmpty) continue;
        map['$book:$chapter:$verse:$marker'] = text;
      }
      return map;
    } catch (_) {
      // A malformed companion shouldn't abort the Bible import — just skip the
      // cross-references and leave the (letterless) markers to be hidden.
      return const {};
    } finally {
      db.close();
    }
  }
}

/// Renders a MyBible cross-reference cell — HTML such as
/// `<a href='B:500 1:1'>JHN 1:1</a>,<a href='B:500 1:3'>3</a>` — into the
/// footnote body shown in the reader. Each link becomes a compact, self-
/// describing token `{book:chapter:verse|label}` (MyBible book numbers, matching
/// [mybibleBookMap]) that the reader turns into a tappable reference; the
/// separators between links are kept as plain text. So the example yields
/// `{500:1:1|JHN 1:1}, {500:1:3|3}`. Input with no links (an ordinary textual
/// footnote) passes through as plain, de-entitied text.
String renderMyBibleCrossRef(String rawHtml) {
  if (rawHtml.isEmpty) return '';

  String plain(String fragment) =>
      html_parser.parse(fragment).body?.text ?? fragment;

  final anchor = RegExp(
    "<a\\b[^>]*?href=['\"]B:(\\d+)\\s+(\\d+):(\\d+)[^'\"]*['\"][^>]*>(.*?)</a>",
    caseSensitive: false,
    dotAll: true,
  );

  final out = StringBuffer();
  var last = 0;
  for (final m in anchor.allMatches(rawHtml)) {
    out.write(plain(rawHtml.substring(last, m.start)));
    final label = plain(m.group(4) ?? '').trim();
    out.write('{${m.group(1)}:${m.group(2)}:${m.group(3)}|$label}');
    last = m.end;
  }
  out.write(plain(rawHtml.substring(last)));

  return out
      .toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\s*;\s*'), '; ')
      .replaceAll(RegExp(r'\s*,\s*'), ', ')
      .trim();
}
