import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/user_tables.dart';

part 'user_store.g.dart';

@DriftDatabase(tables: [
  Highlights, Notes, Bookmarks, Journals, Prayers, 
  ReadingProgresses, TimeTrackers, Achievements, NavigationHistories,
  ReadingPlans, ReadingPlanDays, ReadingPlanItems
])
class UserStore extends _$UserStore {
  UserStore([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 6;

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
            INSERT INTO user_search(rowid, type, reference_id, text_content) VALUES (new.id, 'note', new.id, new.content);
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
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Destructive upgrade: drop all tables and recreate them
          for (final table in allTables) {
            await m.drop(table);
          }
          await m.issueCustomQuery('DROP TABLE IF EXISTS user_search;');
          await m.createAll();
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS user_search USING fts5(type UNINDEXED, reference_id UNINDEXED, text_content);
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
              INSERT INTO user_search(rowid, type, reference_id, text_content) VALUES (new.id, 'note', new.id, new.content);
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
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'user.db'));
    return NativeDatabase.createInBackground(file);
  });
}
