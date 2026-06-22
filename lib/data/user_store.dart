import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
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
          CREATE TRIGGER IF NOT EXISTS sermons_ai AFTER INSERT ON sermons BEGIN
            INSERT INTO user_search(type, reference_id, text_content) VALUES ('sermon', new.id, new.title || ' ' || COALESCE(new.series, '') || ' ' || COALESCE(new.content_plain, ''));
          END;
        ''');
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS sermons_au AFTER UPDATE ON sermons BEGIN
            UPDATE user_search SET text_content = new.title || ' ' || COALESCE(new.series, '') || ' ' || COALESCE(new.content_plain, '') WHERE type = 'sermon' AND reference_id = new.id;
          END;
        ''');
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS sermons_ad AFTER DELETE ON sermons BEGIN
            DELETE FROM user_search WHERE type = 'sermon' AND reference_id = old.id;
          END;
        ''');
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
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'user.db'));
    return NativeDatabase.createInBackground(file, setup: (db) {
      db.execute('PRAGMA journal_mode=WAL;');
      db.execute('PRAGMA busy_timeout=10000;');
      db.execute('PRAGMA synchronous=NORMAL;');
    });
  });
}
