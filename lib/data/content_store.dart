import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'app_paths.dart';
import 'package:path/path.dart' as p;

import 'tables/content_tables.dart';
import 'fts_text.dart';
import 'importer/mybible_verse_parser.dart';

part 'content_store.g.dart';

@DriftDatabase(
  tables: [
    Versions,
    Books,
    Verses,
    CrossReferences,
    Commentaries,
    CommentaryEntries,
    Dictionaries,
    DictionaryEntries,
    Subheadings,
    Devotionals,
    DevotionalEntries,
    Topics,
    TopicEntries,
    TopicReferences,
    Places,
    PlaceVerses,
  ],
)
class ContentStore extends _$ContentStore {
  ContentStore([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Create each entity only if it isn't already present, so a partial or
        // interrupted onCreate can be re-run safely. Drift only bumps the
        // stored schema version once the whole strategy completes; if onCreate
        // fails midway, some tables stay committed with the version still at 0,
        // and the next open re-runs onCreate. A plain m.createAll() would then
        // throw "table already exists" and wedge every future open — leaving
        // the user with no content DB and unable to install one. See
        // [_createIfNotExists].
        for (final entity in allSchemaEntities) {
          await _createIfNotExists(m, entity);
        }
        await customStatement('''
          CREATE VIRTUAL TABLE IF NOT EXISTS content_search USING fts5(type UNINDEXED, reference_id UNINDEXED, text_content);
        ''');
        // content_vocab powers word autocomplete; without this, fresh installs
        // (which only run onCreate, not onUpgrade) would have no vocabulary.
        await customStatement('''
          CREATE VIRTUAL TABLE IF NOT EXISTS content_vocab USING fts5vocab(content_search, 'row');
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(subheadings);
        }
        if (from < 3) {
          await customStatement('DELETE FROM books WHERE id NOT IN (SELECT MAX(id) FROM books GROUP BY version_id, book_order)');
          await customStatement('DELETE FROM verses WHERE book_id NOT IN (SELECT id FROM books)');
          await customStatement('DELETE FROM subheadings WHERE rowid NOT IN (SELECT MAX(rowid) FROM subheadings GROUP BY version_id, book_order, chapter, verse, order_if_several, text_content)');
          await customStatement('DELETE FROM commentaries WHERE id NOT IN (SELECT MAX(id) FROM commentaries GROUP BY abbreviation)');
          await customStatement('DELETE FROM commentary_entries WHERE commentary_id NOT IN (SELECT id FROM commentaries)');
          await customStatement('DELETE FROM dictionaries WHERE id NOT IN (SELECT MAX(id) FROM dictionaries GROUP BY abbreviation)');
          await customStatement('DELETE FROM dictionary_entries WHERE dictionary_id NOT IN (SELECT id FROM dictionaries)');
        }
        if (from < 4) {
          await m.createTable(devotionals);
          await m.createTable(devotionalEntries);
        }
        if (from < 5) {
          await m.addColumn(crossReferences, crossReferences.votes);
          await customStatement('DELETE FROM cross_references');
        }
        if (from < 6) {
          try {
            await customStatement('''
              CREATE VIRTUAL TABLE IF NOT EXISTS content_vocab USING fts5vocab(content_search, 'row');
            ''');
          } catch (e) {
            // It might fail if FTS5 vocab is unsupported, handle gracefully
          }
        }
        if (from < 7) {
          // Retry creating content_vocab in case it failed in schema 6 due to missing sqlite3_flutter_libs
          try {
            await customStatement('''
              CREATE VIRTUAL TABLE IF NOT EXISTS content_vocab USING fts5vocab(content_search, 'row');
            ''');
          } catch (e) {
            // Ignore
          }
        }
        if (from < 8) {
          await m.addColumn(versions, versions.about);
          await m.addColumn(commentaries, commentaries.about);
          await m.addColumn(dictionaries, dictionaries.about);
          await m.addColumn(subheadings, subheadings.about);
          await m.addColumn(devotionals, devotionals.about);
        }
        if (from < 9) {
          await _createIfNotExists(m, topics);
          await _createIfNotExists(m, topicEntries);
          await _createIfNotExists(m, topicReferences);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_topic_ref_location '
            'ON topic_references (book_name, chapter)',
          );
        }
        if (from < 10) {
          await _createIfNotExists(m, places);
          await _createIfNotExists(m, placeVerses);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_place_verse_location '
            'ON place_verses (book_name, chapter)',
          );
        }
      },
    );
  }

  /// Creates [entity] (a table, index, view, …) only if it isn't already
  /// present.
  ///
  /// Both onCreate and onUpgrade can be re-entered after a partial or
  /// interrupted run — drift only bumps the stored schema version once the
  /// whole strategy completes, so a failure midway leaves some statements
  /// applied and the version unchanged. On the next open the same block runs
  /// again; a plain [Migrator.create] would then throw "already exists" and
  /// wedge every future open (the content DB never finishes opening, so the
  /// reader hangs). Skipping entities that already exist makes the block
  /// idempotent.
  Future<void> _createIfNotExists(Migrator m, DatabaseSchemaEntity entity) async {
    final existing = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE name = ?",
      variables: [Variable<String>(entity.entityName)],
    ).get();
    if (existing.isEmpty) {
      try {
        await m.create(entity);
      } catch (_) {
        // TOCTOU: a transiently double-opened engine on first launch (two
        // connections racing this migration) can create the entity between the
        // check above and m.create, making the non-IF-NOT-EXISTS create throw
        // "already exists". Re-check sqlite_master; swallow only if the entity
        // is now present (the race is benign), otherwise rethrow the real error.
        final present = await customSelect(
          "SELECT 1 FROM sqlite_master WHERE name = ?",
          variables: [Variable<String>(entity.entityName)],
        ).get();
        if (present.isEmpty) rethrow;
      }
    }
  }

  Future<void> deleteVersion(String versionId) async {
    await transaction(() async {
      await customStatement(
        "DELETE FROM content_search WHERE type='verse' AND reference_id IN (SELECT v.id FROM verses v JOIN books b ON v.book_id = b.id WHERE b.version_id = ?)",
        [versionId],
      );

      final bookIds = await (select(
        books,
      )..where((b) => b.versionId.equals(versionId))).map((b) => b.id).get();
      if (bookIds.isNotEmpty) {
        await (delete(verses)..where((v) => v.bookId.isIn(bookIds))).go();
        await (delete(books)..where((b) => b.id.isIn(bookIds))).go();
      }
      await (delete(subheadings)..where((s) => s.versionId.equals(versionId))).go();
      await (delete(versions)..where((v) => v.id.equals(versionId))).go();
    });
  }

  Future<void> deleteCommentary(int id) async {
    await transaction(() async {
      await customStatement(
        "DELETE FROM content_search WHERE type='commentary' AND reference_id IN (SELECT id FROM commentary_entries WHERE commentary_id = ?)",
        [id],
      );
      await (delete(
        commentaryEntries,
      )..where((c) => c.commentaryId.equals(id))).go();
      await (delete(commentaries)..where((c) => c.id.equals(id))).go();
    });
  }

  Future<void> deleteDictionary(int id) async {
    await transaction(() async {
      await customStatement(
        "DELETE FROM content_search WHERE type='dictionary' AND reference_id IN (SELECT id FROM dictionary_entries WHERE dictionary_id = ?)",
        [id],
      );
      await (delete(
        dictionaryEntries,
      )..where((d) => d.dictionaryId.equals(id))).go();
      await (delete(dictionaries)..where((d) => d.id.equals(id))).go();
    });
  }

  Future<void> deleteDevotional(int id) async {
    await transaction(() async {
      await customStatement(
        "DELETE FROM content_search WHERE type='devotional' AND reference_id IN (SELECT id FROM devotional_entries WHERE devotional_id = ?)",
        [id],
      );
      await (delete(
        devotionalEntries,
      )..where((d) => d.devotionalId.equals(id))).go();
      await (delete(devotionals)..where((d) => d.id.equals(id))).go();
    });
  }

  /// Indexes a freshly-imported HTML content type ('commentary' or
  /// 'devotional') into the search index with markup stripped. [table] and
  /// [fkColumn] are internal constants, never user input.
  Future<void> indexStrippedEntries(
    String type,
    String table,
    String fkColumn,
    int fkValue,
  ) async {
    final rows = await customSelect(
      'SELECT id, text_content AS t FROM $table WHERE $fkColumn = ?',
      variables: [Variable.withInt(fkValue)],
    ).get();
    await _insertCleanedRows(type, rows, stripMarkupForIndex);
  }

  /// Rebuilds the entire full-text search index from the source tables,
  /// stripping markup from HTML content types. Safe to run on demand to clean
  /// an index that was populated before markup stripping existed.
  ///
  /// NOTE: if you change *how* content is indexed here (what gets stripped,
  /// tokenized, or which columns are indexed), existing users' indexes go
  /// stale. Bump `kSearchIndexGeneration` in `lib/app/shared_prefs.dart` in the
  /// same release so the What's New dialog prompts them to rebuild.
  Future<void> rebuildSearchIndex() async {
    await transaction(() async {
      await customStatement('DELETE FROM content_search');
      // Verses: strip MyBible inline markup (Strong's/footnote/format tags) so
      // phrase search isn't broken by tag tokens interleaved between words.
      // Matches the importer; the parser leaves already-plain (e.g. OSIS) text
      // untouched. This must NOT use the raw text_content column.
      await _insertCleanedRows(
        'verse',
        await customSelect('SELECT id, text_content AS t FROM verses').get(),
        mybibleVersePlainText,
      );
      // Plain-text types: fast bulk insert, no stripping needed.
      await customStatement(
        "INSERT INTO content_search(type, reference_id, text_content) "
        "SELECT 'dictionary', id, word FROM dictionary_entries",
      );
      await customStatement(
        "INSERT INTO content_search(type, reference_id, text_content) "
        "SELECT 'topic', id, name FROM topics",
      );
      // HTML types: strip markup before indexing.
      await _insertCleanedRows(
        'commentary',
        await customSelect(
          'SELECT id, text_content AS t FROM commentary_entries',
        ).get(),
        stripMarkupForIndex,
      );
      await _insertCleanedRows(
        'devotional',
        await customSelect(
          'SELECT id, text_content AS t FROM devotional_entries',
        ).get(),
        stripMarkupForIndex,
      );
    });
  }

  /// Cleans each row's `t` column with [clean] and inserts (type, id, text)
  /// into content_search in chunked multi-row statements (kept well under
  /// SQLite's bound-variable limit). Rows whose cleaned text is empty are
  /// skipped so the index stays free of blank entries.
  Future<void> _insertCleanedRows(
    String type,
    List<QueryRow> rows,
    String Function(String) clean,
  ) async {
    const chunkSize = 200;
    for (var i = 0; i < rows.length; i += chunkSize) {
      final end = (i + chunkSize < rows.length) ? i + chunkSize : rows.length;
      final chunk = rows.sublist(i, end);
      final cleaned = <(int, String)>[];
      for (final row in chunk) {
        final text = clean(row.read<String>('t'));
        if (text.isNotEmpty) cleaned.add((row.read<int>('id'), text));
      }
      if (cleaned.isEmpty) continue;
      final placeholders = List.filled(cleaned.length, '(?, ?, ?)').join(', ');
      final args = <Variable>[];
      for (final (id, text) in cleaned) {
        args.add(Variable.withString(type));
        args.add(Variable.withInt(id));
        args.add(Variable.withString(text));
      }
      await customInsert(
        'INSERT INTO content_search(type, reference_id, text_content) '
        'VALUES $placeholders',
        variables: args,
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await appDataDir();
    final file = File(p.join(dbFolder.path, 'content.db'));
    return NativeDatabase.createInBackground(file, setup: (db) {
      // Set busy_timeout *before* switching to WAL. Enabling WAL needs a brief
      // exclusive lock, and if another connection is opening or recovering the
      // same database concurrently at startup, the switch would otherwise fail
      // instantly with SQLITE_BUSY (seen as code 261, BUSY_RECOVERY). With the
      // timeout set first, the switch waits for the other connection instead.
      db.execute('PRAGMA busy_timeout=10000;');
      db.execute('PRAGMA journal_mode=WAL;');
      db.execute('PRAGMA synchronous=NORMAL;');
    });
  });
}
