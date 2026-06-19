import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'package:drift/drift.dart';
import '../../data/content_store.dart';
import '../../data/content_manager_api.dart';
import 'mybible_verse_parser.dart';
import '../../data/mybible_book_map.dart';

class MyBibleImporter {
  final ContentStore store;

  MyBibleImporter(this.store);

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
      default:
        print(
          'Skipping unsupported module file type: $inferredType for ${sqliteFile.path}',
        );
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
            ),
            mode: InsertMode.insertOrReplace,
          );

      final Map<int, int> bookIdMap = {};
      final booksQuery = db.select(
        'SELECT book_number, short_name, long_name FROM books ORDER BY book_number',
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

      final versesQuery = db.select(
        'SELECT book_number, chapter, verse, text FROM verses ORDER BY book_number, chapter, verse',
      );

      final parser = MyBibleVerseParser();

      await store.batch((batch) {
        for (final row in versesQuery) {
          if (row['book_number'] == null ||
              row['chapter'] == null ||
              row['verse'] == null)
            continue;
          final bookNumber = num.parse(row['book_number'].toString()).toInt();
          final chapter = num.parse(row['chapter'].toString()).toInt();
          final verse = num.parse(row['verse'].toString()).toInt();
          final text = row['text']?.toString() ?? '';

          final bookId = bookIdMap[bookNumber];
          if (bookId == null) continue;

          final segments = parser.parseVerse(text);
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
          'SELECT book_number, chapter, verse, order_if_several, title FROM stories ORDER BY book_number, chapter, verse, order_if_several',
        );

        await store.batch((batch) {
          for (final row in storiesQuery) {
            if (row['book_number'] == null ||
                row['chapter'] == null ||
                row['verse'] == null) continue;

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

      // Update FTS5 index for this version
      await store.customStatement(
        '''
        INSERT INTO content_search(type, reference_id, text_content) 
        SELECT 'verse', v.id, v.text_content 
        FROM verses v 
        JOIN books b ON v.book_id = b.id 
        WHERE b.version_id = ?
      ''',
        [versionId],
      );
    } finally {
      db.dispose();
    }
  }

  Future<void> _importSubheadings(File sqliteFile, Ph4Module module) async {
    final db = sqlite3.open(sqliteFile.path);

    try {
      final versionId = module.abbr.toUpperCase();
      await store.deleteVersion(versionId);

      await store
          .into(store.versions)
          .insert(
            VersionsCompanion.insert(
              id: versionId,
              abbreviation: module.abbr,
              name: module.title,
              language: const Value('en'),
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
          'SELECT book_number, chapter, verse, order_if_several, title FROM stories ORDER BY book_number, chapter, verse, order_if_several',
        );

        await store.batch((batch) {
          for (final row in storiesQuery) {
            if (row['book_number'] == null ||
                row['chapter'] == null ||
                row['verse'] == null) continue;

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
                row['verse'] == null) continue;

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
      db.dispose();
    }
  }

  Future<void> _importCommentary(File sqliteFile, Ph4Module module) async {
    final db = sqlite3.open(sqliteFile.path);

    try {
      final existing = await (store.select(store.commentaries)..where((c) => c.abbreviation.equals(module.abbr))).get();
      for (final e in existing) {
        await store.deleteCommentary(e.id);
      }

      final commentaryId = await store
          .into(store.commentaries)
          .insert(
            CommentariesCompanion.insert(
              abbreviation: module.abbr,
              name: module.title,
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

      // Update FTS5 index for this commentary
      await store.customStatement(
        '''
        INSERT INTO content_search(type, reference_id, text_content)
        SELECT 'commentary', id, text_content
        FROM commentary_entries
        WHERE commentary_id = ?
      ''',
        [commentaryId],
      );
    } finally {
      db.dispose();
    }
  }

  Future<void> _importDictionary(File sqliteFile, Ph4Module module) async {
    final db = sqlite3.open(sqliteFile.path);

    try {
      final existing = await (store.select(store.dictionaries)..where((d) => d.abbreviation.equals(module.abbr))).get();
      for (final e in existing) {
        await store.deleteDictionary(e.id);
      }

      final dictionaryId = await store
          .into(store.dictionaries)
          .insert(
            DictionariesCompanion.insert(
              abbreviation: module.abbr,
              name: module.title,
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
      db.dispose();
    }
  }

  String _bookNumberToName(int number) {
    return mybibleBookMap[number] ?? 'Book $number';
  }
}
