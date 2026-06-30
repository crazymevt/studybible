import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'app_paths.dart';

import 'tables/user_tables.dart';
import 'fts_text.dart';

part 'user_store.g.dart';

@DriftDatabase(
  tables: [
    Highlights,
    Notes,
    Bookmarks,
    Journals,
    Prayers,
    ReadingProgresses,
    TimeTrackers,
    Achievements,
    NavigationHistories,
    ReadingPlans,
    ReadingPlanDays,
    ReadingPlanItems,
    Sermons,
    Tags,
    EntityTags,
  ],
)
class UserStore extends _$UserStore {
  UserStore([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 17;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await customStatement('''
          CREATE VIRTUAL TABLE IF NOT EXISTS user_search USING fts5(type UNINDEXED, reference_id UNINDEXED, text_content);
        ''');
        await _installSearchTriggers();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Destructive upgrade: drop all tables and recreate them
          for (final table in allTables) {
            await m.drop(table);
          }
          await customStatement('DROP TABLE IF EXISTS user_search;');
          await m.createAll();
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS user_search USING fts5(type UNINDEXED, reference_id UNINDEXED, text_content);
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('note', new.id, new.content);
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
              UPDATE user_search SET text_content = new.content WHERE type = 'note' AND reference_id = new.id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
              DELETE FROM user_search WHERE type = 'note' AND reference_id = old.id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS notes_soft_delete_au AFTER UPDATE ON notes 
            WHEN new.deleted = 1 AND old.deleted = 0
            BEGIN
              DELETE FROM user_search WHERE type = 'note' AND reference_id = old.id;
            END;
          ''');
          // Note: tags triggers are added in <10 and <11 blocks, so we don't need to add them here since the migration path will just run those blocks next.
        }
        if (from < 3) {
          await m.createTable(journals);
          await m.createTable(prayers);
        }
        if (from < 4) {
          await m.createTable(readingProgresses);
          await m.createTable(timeTrackers);
          await m.createTable(achievements);
        }
        if (from < 5) {
          await m.createTable(navigationHistories);
        }
        if (from < 6) {
          await m.createTable(readingPlans);
          await m.createTable(readingPlanDays);
          await m.createTable(readingPlanItems);
        }
        if (from < 7) {
          await m.addColumn(notes, notes.selectedVerses);
        }
        if (from < 8) {
          await customStatement('DROP TRIGGER IF EXISTS notes_ai;');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('note', new.id, new.content);
            END;
          ''');
        }
        if (from < 9) {
          await m.createTable(sermons);
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS sermons_ai AFTER INSERT ON sermons BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('sermon', new.id, new.title || ' ' || COALESCE(new.series, '') || ' ' || new.content);
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS sermons_au AFTER UPDATE ON sermons BEGIN
              UPDATE user_search SET text_content = new.title || ' ' || COALESCE(new.series, '') || ' ' || new.content WHERE type = 'sermon' AND reference_id = new.id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS sermons_ad AFTER DELETE ON sermons BEGIN
              DELETE FROM user_search WHERE type = 'sermon' AND reference_id = old.id;
            END;
          ''');
        }
        if (from < 10) {
          await m.createTable(tags);
          await m.createTable(entityTags);
          // Insert trigger to add tags into search index automatically
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS tags_ai AFTER INSERT ON entity_tags BEGIN
              INSERT INTO user_search(type, reference_id, text_content) 
              SELECT new.entity_type, new.entity_id, '#' || tags.name 
              FROM tags WHERE tags.id = new.tag_id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS tags_ad AFTER DELETE ON entity_tags BEGIN
              DELETE FROM user_search WHERE text_content = (SELECT '#' || name FROM tags WHERE id = old.tag_id) AND reference_id = old.entity_id AND type = old.entity_type;
            END;
          ''');
        }
        if (from < 11) {
          // Add AFTER UPDATE trigger to handle soft deletes
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS tags_au AFTER UPDATE ON entity_tags 
            WHEN new.deleted = 1 AND old.deleted = 0
            BEGIN
              DELETE FROM user_search WHERE text_content = (SELECT '#' || name FROM tags WHERE id = old.tag_id) AND reference_id = old.entity_id AND type = old.entity_type;
            END;
          ''');
          
          // Cleanup any orphaned tags from user_search that were soft-deleted before this trigger existed
          await customStatement('''
            DELETE FROM user_search 
            WHERE rowid IN (
              SELECT us.rowid FROM user_search us
              JOIN entity_tags et ON us.reference_id = et.entity_id AND us.type = et.entity_type
              JOIN tags t ON et.tag_id = t.id
              WHERE et.deleted = 1 AND us.text_content = '#' || t.name
            );
          ''');
        }
        if (from < 12) {
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS journals_ai AFTER INSERT ON journals BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('journal', new.id, new.title || ' ' || new.content);
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS journals_au AFTER UPDATE ON journals BEGIN
              UPDATE user_search SET text_content = new.title || ' ' || new.content WHERE type = 'journal' AND reference_id = new.id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS journals_ad AFTER DELETE ON journals BEGIN
              DELETE FROM user_search WHERE type = 'journal' AND reference_id = old.id;
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS prayers_ai AFTER INSERT ON prayers BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('prayer', new.id, new.name || ' ' || new.description);
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS prayers_au AFTER UPDATE ON prayers BEGIN
              UPDATE user_search SET text_content = new.name || ' ' || new.description WHERE type = 'prayer' AND reference_id = new.id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS prayers_ad AFTER DELETE ON prayers BEGIN
              DELETE FROM user_search WHERE type = 'prayer' AND reference_id = old.id;
            END;
          ''');

          // Seed existing journals and prayers into the search index
          await customStatement('''
            INSERT INTO user_search(type, reference_id, text_content)
            SELECT 'journal', id, title || ' ' || content FROM journals WHERE deleted = 0;
          ''');
          await customStatement('''
            INSERT INTO user_search(type, reference_id, text_content)
            SELECT 'prayer', id, name || ' ' || description FROM prayers WHERE deleted = 0;
          ''');
        }
        if (from < 13) {
          // Sermons are rich text (Quill Delta JSON). Index a plain-text
          // projection instead of the raw JSON so the search index/snippets
          // aren't polluted with markup.
          await m.addColumn(sermons, sermons.contentPlain);

          // Drop the sermon triggers so the backfill below doesn't fire them,
          // then recreate them to index content_plain.
          await customStatement('DROP TRIGGER IF EXISTS sermons_ai;');
          await customStatement('DROP TRIGGER IF EXISTS sermons_au;');

          // Backfill content_plain for existing sermons (Delta -> plain text).
          final existingSermons =
              await customSelect('SELECT id, content FROM sermons').get();
          for (final row in existingSermons) {
            await customStatement('UPDATE sermons SET content_plain = ? WHERE id = ?', [
              deltaToPlainText(row.read<String>('content')),
              row.read<String>('id'),
            ]);
          }

          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS sermons_ai AFTER INSERT ON sermons BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('sermon', new.id, new.title || ' ' || COALESCE(new.series, '') || ' ' || COALESCE(new.content_plain, ''));
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS sermons_au AFTER UPDATE ON sermons BEGIN
              UPDATE user_search SET text_content = new.title || ' ' || COALESCE(new.series, '') || ' ' || COALESCE(new.content_plain, '') WHERE type = 'sermon' AND reference_id = new.id;
            END;
          ''');

          // Re-index existing sermons with the plain text.
          await customStatement("DELETE FROM user_search WHERE type = 'sermon';");
          await customStatement('''
            INSERT INTO user_search(type, reference_id, text_content)
            SELECT 'sermon', id, title || ' ' || COALESCE(series, '') || ' ' || COALESCE(content_plain, '') FROM sermons WHERE deleted = 0;
          ''');
        }
        if (from < 14) {
          // Soft-delete triggers for search index cleanup
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS notes_soft_delete_au AFTER UPDATE ON notes 
            WHEN new.deleted = 1 AND old.deleted = 0
            BEGIN
              DELETE FROM user_search WHERE type = 'note' AND reference_id = old.id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS sermons_soft_delete_au AFTER UPDATE ON sermons 
            WHEN new.deleted = 1 AND old.deleted = 0
            BEGIN
              DELETE FROM user_search WHERE type = 'sermon' AND reference_id = old.id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS journals_soft_delete_au AFTER UPDATE ON journals 
            WHEN new.deleted = 1 AND old.deleted = 0
            BEGIN
              DELETE FROM user_search WHERE type = 'journal' AND reference_id = old.id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS prayers_soft_delete_au AFTER UPDATE ON prayers 
            WHEN new.deleted = 1 AND old.deleted = 0
            BEGIN
              DELETE FROM user_search WHERE type = 'prayer' AND reference_id = old.id;
            END;
          ''');

          // Cleanup orphaned items from FTS index
          await customStatement('''
            DELETE FROM user_search WHERE type = 'note' AND reference_id IN (SELECT id FROM notes WHERE deleted = 1);
          ''');
          await customStatement('''
            DELETE FROM user_search WHERE type = 'sermon' AND reference_id IN (SELECT id FROM sermons WHERE deleted = 1);
          ''');
          await customStatement('''
            DELETE FROM user_search WHERE type = 'journal' AND reference_id IN (SELECT id FROM journals WHERE deleted = 1);
          ''');
          await customStatement('''
            DELETE FROM user_search WHERE type = 'prayer' AND reference_id IN (SELECT id FROM prayers WHERE deleted = 1);
          ''');
        }

        if (from < 16) {
          // Drop all existing triggers
          await customStatement('DROP TRIGGER IF EXISTS notes_ai;');
          await customStatement('DROP TRIGGER IF EXISTS notes_au;');
          await customStatement('DROP TRIGGER IF EXISTS notes_ad;');
          await customStatement('DROP TRIGGER IF EXISTS sermons_ai;');
          await customStatement('DROP TRIGGER IF EXISTS sermons_au;');
          await customStatement('DROP TRIGGER IF EXISTS sermons_ad;');
          await customStatement('DROP TRIGGER IF EXISTS journals_ai;');
          await customStatement('DROP TRIGGER IF EXISTS journals_au;');
          await customStatement('DROP TRIGGER IF EXISTS journals_ad;');
          await customStatement('DROP TRIGGER IF EXISTS prayers_ai;');
          await customStatement('DROP TRIGGER IF EXISTS prayers_au;');
          await customStatement('DROP TRIGGER IF EXISTS prayers_ad;');
          await customStatement('DROP TRIGGER IF EXISTS notes_soft_delete_au;');
          await customStatement('DROP TRIGGER IF EXISTS sermons_soft_delete_au;');
          await customStatement('DROP TRIGGER IF EXISTS journals_soft_delete_au;');
          await customStatement('DROP TRIGGER IF EXISTS prayers_soft_delete_au;');

          // Recreate with robust INSERT OR REPLACE support
          await customStatement('''
            CREATE TRIGGER notes_ai AFTER INSERT ON notes 
            BEGIN
              DELETE FROM user_search WHERE type = 'note' AND reference_id = new.id;
              INSERT INTO user_search(type, reference_id, text_content) SELECT 'note', new.id, new.content WHERE new.deleted = 0;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER notes_au AFTER UPDATE ON notes 
            BEGIN
              DELETE FROM user_search WHERE type = 'note' AND reference_id = new.id;
              INSERT INTO user_search(type, reference_id, text_content) SELECT 'note', new.id, new.content WHERE new.deleted = 0;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER notes_ad AFTER DELETE ON notes 
            BEGIN
              DELETE FROM user_search WHERE type = 'note' AND reference_id = old.id;
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER sermons_ai AFTER INSERT ON sermons 
            BEGIN
              DELETE FROM user_search WHERE type = 'sermon' AND reference_id = new.id;
              INSERT INTO user_search(type, reference_id, text_content) SELECT 'sermon', new.id, new.title || ' ' || COALESCE(new.series, '') || ' ' || COALESCE(new.content_plain, '') WHERE new.deleted = 0;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER sermons_au AFTER UPDATE ON sermons 
            BEGIN
              DELETE FROM user_search WHERE type = 'sermon' AND reference_id = new.id;
              INSERT INTO user_search(type, reference_id, text_content) SELECT 'sermon', new.id, new.title || ' ' || COALESCE(new.series, '') || ' ' || COALESCE(new.content_plain, '') WHERE new.deleted = 0;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER sermons_ad AFTER DELETE ON sermons 
            BEGIN
              DELETE FROM user_search WHERE type = 'sermon' AND reference_id = old.id;
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER journals_ai AFTER INSERT ON journals 
            BEGIN
              DELETE FROM user_search WHERE type = 'journal' AND reference_id = new.id;
              INSERT INTO user_search(type, reference_id, text_content) SELECT 'journal', new.id, new.title || ' ' || new.content WHERE new.deleted = 0;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER journals_au AFTER UPDATE ON journals 
            BEGIN
              DELETE FROM user_search WHERE type = 'journal' AND reference_id = new.id;
              INSERT INTO user_search(type, reference_id, text_content) SELECT 'journal', new.id, new.title || ' ' || new.content WHERE new.deleted = 0;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER journals_ad AFTER DELETE ON journals 
            BEGIN
              DELETE FROM user_search WHERE type = 'journal' AND reference_id = old.id;
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER prayers_ai AFTER INSERT ON prayers 
            BEGIN
              DELETE FROM user_search WHERE type = 'prayer' AND reference_id = new.id;
              INSERT INTO user_search(type, reference_id, text_content) SELECT 'prayer', new.id, new.name || ' ' || new.description WHERE new.deleted = 0;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER prayers_au AFTER UPDATE ON prayers 
            BEGIN
              DELETE FROM user_search WHERE type = 'prayer' AND reference_id = new.id;
              INSERT INTO user_search(type, reference_id, text_content) SELECT 'prayer', new.id, new.name || ' ' || new.description WHERE new.deleted = 0;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER prayers_ad AFTER DELETE ON prayers 
            BEGIN
              DELETE FROM user_search WHERE type = 'prayer' AND reference_id = old.id;
            END;
          ''');

          // Wipe and rebuild the FTS index completely to guarantee perfection
          await customStatement('DELETE FROM user_search;');
          await customStatement("INSERT INTO user_search(type, reference_id, text_content) SELECT 'note', id, content FROM notes WHERE deleted = 0;");
          await customStatement("INSERT INTO user_search(type, reference_id, text_content) SELECT 'journal', id, title || ' ' || content FROM journals WHERE deleted = 0;");
          await customStatement("INSERT INTO user_search(type, reference_id, text_content) SELECT 'sermon', id, title || ' ' || COALESCE(series, '') || ' ' || COALESCE(content_plain, '') FROM sermons WHERE deleted = 0;");
          await customStatement("INSERT INTO user_search(type, reference_id, text_content) SELECT 'prayer', id, name || ' ' || description FROM prayers WHERE deleted = 0;");
        }

        if (from < 15) {
          // Drop all existing _ai and _au triggers
          await customStatement('DROP TRIGGER IF EXISTS notes_ai;');
          await customStatement('DROP TRIGGER IF EXISTS notes_au;');
          await customStatement('DROP TRIGGER IF EXISTS sermons_ai;');
          await customStatement('DROP TRIGGER IF EXISTS sermons_au;');
          await customStatement('DROP TRIGGER IF EXISTS journals_ai;');
          await customStatement('DROP TRIGGER IF EXISTS journals_au;');
          await customStatement('DROP TRIGGER IF EXISTS prayers_ai;');
          await customStatement('DROP TRIGGER IF EXISTS prayers_au;');

          // Recreate with WHEN new.deleted = 0
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes 
            WHEN new.deleted = 0
            BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('note', new.id, new.content);
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes 
            WHEN new.deleted = 0
            BEGIN
              UPDATE user_search SET text_content = new.content WHERE type = 'note' AND reference_id = new.id;
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS sermons_ai AFTER INSERT ON sermons 
            WHEN new.deleted = 0
            BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('sermon', new.id, new.title || ' ' || COALESCE(new.series, '') || ' ' || COALESCE(new.content_plain, ''));
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS sermons_au AFTER UPDATE ON sermons 
            WHEN new.deleted = 0
            BEGIN
              UPDATE user_search SET text_content = new.title || ' ' || COALESCE(new.series, '') || ' ' || COALESCE(new.content_plain, '') WHERE type = 'sermon' AND reference_id = new.id;
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS journals_ai AFTER INSERT ON journals 
            WHEN new.deleted = 0
            BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('journal', new.id, new.title || ' ' || new.content);
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS journals_au AFTER UPDATE ON journals 
            WHEN new.deleted = 0
            BEGIN
              UPDATE user_search SET text_content = new.title || ' ' || new.content WHERE type = 'journal' AND reference_id = new.id;
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS prayers_ai AFTER INSERT ON prayers 
            WHEN new.deleted = 0
            BEGIN
              INSERT INTO user_search(type, reference_id, text_content) VALUES ('prayer', new.id, new.name || ' ' || new.description);
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS prayers_au AFTER UPDATE ON prayers 
            WHEN new.deleted = 0
            BEGIN
              UPDATE user_search SET text_content = new.name || ' ' || new.description WHERE type = 'prayer' AND reference_id = new.id;
            END;
          ''');

          // Cleanup orphaned items from FTS index (again, just in case)
          await customStatement('''
            DELETE FROM user_search WHERE type = 'note' AND reference_id IN (SELECT id FROM notes WHERE deleted = 1);
          ''');
          await customStatement('''
            DELETE FROM user_search WHERE type = 'sermon' AND reference_id IN (SELECT id FROM sermons WHERE deleted = 1);
          ''');
          await customStatement('''
            DELETE FROM user_search WHERE type = 'journal' AND reference_id IN (SELECT id FROM journals WHERE deleted = 1);
          ''');
          await customStatement('''
            DELETE FROM user_search WHERE type = 'prayer' AND reference_id IN (SELECT id FROM prayers WHERE deleted = 1);
          ''');
        }
        if (from < 17) {
          // The v14-v16 migration blocks ran out of order (the `from < 16`
          // block executes before `from < 15` in source order), so every
          // upgraded DB ended up with the old WHEN-based triggers. Those leak
          // soft-deleted rows into the FTS index on INSERT OR REPLACE, because
          // REPLACE's implicit row delete does not fire the AFTER DELETE
          // trigger while recursive_triggers is off. Reinstall the robust
          // triggers and rebuild the index from scratch to heal every install.
          await _installSearchTriggers();
          await _rebuildSearchIndex();
        }
      },
    );
  }

  /// (Re)installs the FTS maintenance triggers for the user-content tables in
  /// their robust form: every INSERT/UPDATE first clears any stale index row
  /// for the id, then re-indexes only when the row is live. The unconditional
  /// DELETE is what makes INSERT OR REPLACE safe -- REPLACE deletes the old
  /// row without firing the AFTER DELETE trigger (recursive_triggers is off),
  /// so the leak is closed inside the INSERT/UPDATE triggers themselves.
  Future<void> _installSearchTriggers() async {
    const configs = [
      ['note', 'notes', 'new.content'],
      [
        'sermon',
        'sermons',
        "new.title || ' ' || COALESCE(new.series, '') || ' ' || COALESCE(new.content_plain, '')"
      ],
      ['journal', 'journals', "new.title || ' ' || new.content"],
      ['prayer', 'prayers', "new.name || ' ' || new.description"],
    ];
    for (final c in configs) {
      final type = c[0];
      final table = c[1];
      final expr = c[2];
      // Drop every prior variant, including the v14-v16 *_soft_delete_au helpers.
      await customStatement('DROP TRIGGER IF EXISTS ${table}_ai;');
      await customStatement('DROP TRIGGER IF EXISTS ${table}_au;');
      await customStatement('DROP TRIGGER IF EXISTS ${table}_ad;');
      await customStatement('DROP TRIGGER IF EXISTS ${table}_soft_delete_au;');
      // CREATE ... IF NOT EXISTS so a transiently double-opened engine on first
      // launch (two connections racing this same migration) can't throw "trigger
      // already exists" between our DROP above and the CREATE here. Every racer
      // installs the identical robust definition, so the end state is one trigger.
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS ${table}_ai AFTER INSERT ON $table BEGIN
          DELETE FROM user_search WHERE type = '$type' AND reference_id = new.id;
          INSERT INTO user_search(type, reference_id, text_content) SELECT '$type', new.id, $expr WHERE new.deleted = 0;
        END;
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS ${table}_au AFTER UPDATE ON $table BEGIN
          DELETE FROM user_search WHERE type = '$type' AND reference_id = new.id;
          INSERT INTO user_search(type, reference_id, text_content) SELECT '$type', new.id, $expr WHERE new.deleted = 0;
        END;
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS ${table}_ad AFTER DELETE ON $table BEGIN
          DELETE FROM user_search WHERE type = '$type' AND reference_id = old.id;
        END;
      ''');
    }
  }

  /// Wipes and repopulates the entire FTS index from the live (non-deleted)
  /// rows of every indexed source, including entity tags.
  Future<void> _rebuildSearchIndex() async {
    await customStatement('DELETE FROM user_search;');
    await customStatement(
        "INSERT INTO user_search(type, reference_id, text_content) SELECT 'note', id, content FROM notes WHERE deleted = 0;");
    await customStatement(
        "INSERT INTO user_search(type, reference_id, text_content) SELECT 'journal', id, title || ' ' || content FROM journals WHERE deleted = 0;");
    await customStatement(
        "INSERT INTO user_search(type, reference_id, text_content) SELECT 'sermon', id, title || ' ' || COALESCE(series, '') || ' ' || COALESCE(content_plain, '') FROM sermons WHERE deleted = 0;");
    await customStatement(
        "INSERT INTO user_search(type, reference_id, text_content) SELECT 'prayer', id, name || ' ' || description FROM prayers WHERE deleted = 0;");
    // Restore tag rows, which share (type, reference_id) with their content row.
    await customStatement('''
      INSERT INTO user_search(type, reference_id, text_content)
      SELECT et.entity_type, et.entity_id, '#' || t.name
      FROM entity_tags et
      JOIN tags t ON et.tag_id = t.id
      WHERE et.deleted = 0;
    ''');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await appDataDir();
    final file = File(p.join(dbFolder.path, 'user.db'));
    return NativeDatabase.createInBackground(file, setup: (db) {
      // Set busy_timeout *before* switching to WAL — see the matching note in
      // content_store.dart. Otherwise the WAL switch can fail instantly with
      // SQLITE_BUSY when another connection is opening the db concurrently.
      db.execute('PRAGMA busy_timeout=10000;');
      db.execute('PRAGMA journal_mode=WAL;');
      db.execute('PRAGMA synchronous=NORMAL;');
    });
  });
}
