import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/content_tables.dart';

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
  ],
)
class ContentStore extends _$ContentStore {
  ContentStore([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await customStatement('''
          CREATE VIRTUAL TABLE IF NOT EXISTS content_search USING fts5(type UNINDEXED, reference_id UNINDEXED, text_content);
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
      },
    );
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'content.db'));
    return NativeDatabase.createInBackground(file, setup: (db) {
      db.execute('PRAGMA journal_mode=WAL;');
    });
  });
}
