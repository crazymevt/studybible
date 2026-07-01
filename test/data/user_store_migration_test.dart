import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:study_bible/data/user_store.dart';

void main() {
  test(
      'upgrade from a pre-17 schema does not fail on journals.content_plain',
      () async {
    final dir = await Directory.systemTemp.createTemp('user_store_migration');
    final file = File('${dir.path}/user.db');
    try {
      // Hand-build a minimal schema matching what a v16 install looks like:
      // sermons already carry content_plain (added v13) but journals do NOT
      // (that column is not added until v21). Only the columns the v17+
      // migration blocks touch need to exist.
      final raw = sqlite.sqlite3.open(file.path);
      raw.execute(
          'CREATE TABLE notes (id TEXT NOT NULL PRIMARY KEY, content TEXT NOT NULL DEFAULT \'\', deleted INTEGER NOT NULL DEFAULT 0);');
      raw.execute(
          'CREATE TABLE journals (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL DEFAULT \'\', content TEXT NOT NULL DEFAULT \'\', deleted INTEGER NOT NULL DEFAULT 0);');
      raw.execute(
          'CREATE TABLE sermons (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL DEFAULT \'\', series TEXT, content TEXT NOT NULL DEFAULT \'\', content_plain TEXT, deleted INTEGER NOT NULL DEFAULT 0);');
      raw.execute(
          'CREATE TABLE prayers (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL DEFAULT \'\', description TEXT NOT NULL DEFAULT \'\', deleted INTEGER NOT NULL DEFAULT 0);');
      raw.execute(
          'CREATE TABLE tags (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL DEFAULT \'\');');
      raw.execute(
          'CREATE TABLE entity_tags (entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, tag_id TEXT NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);');
      raw.execute(
          'CREATE VIRTUAL TABLE user_search USING fts5(type UNINDEXED, reference_id UNINDEXED, text_content);');
      // Seed a journal so the v17 rebuild and the v21 backfill both touch a row.
      raw.execute(
          "INSERT INTO journals (id, title, content, deleted) VALUES ('j1', 'Title', 'Body', 0);");
      raw.execute('PRAGMA user_version = 16;');
      raw.close();

      // Opening the store runs onUpgrade(16 -> 21). Before the fix this threw
      // "no such column: content_plain" in the v17 heal step.
      final store = UserStore(NativeDatabase(file));
      await store.customSelect('SELECT 1').get(); // force the lazy open + migrate

      // The column exists and the journal was indexed.
      final hasColumn = await store
          .customSelect(
              "SELECT 1 FROM pragma_table_info('journals') WHERE name = 'content_plain'")
          .get();
      expect(hasColumn, isNotEmpty);

      final indexed = await store
          .customSelect(
              "SELECT count(*) AS c FROM user_search WHERE type = 'journal' AND reference_id = 'j1'")
          .getSingle();
      expect(indexed.read<int>('c'), greaterThan(0));

      await store.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('upgrade from the schema-1 destructive path completes cleanly',
      () async {
    final dir = await Directory.systemTemp.createTemp('user_store_v1');
    final file = File('${dir.path}/user.db');
    try {
      // A schema-1 install: just the original notes table and the FTS index.
      final raw = sqlite.sqlite3.open(file.path);
      raw.execute(
          'CREATE TABLE notes (id TEXT NOT NULL PRIMARY KEY, content TEXT NOT NULL DEFAULT \'\', deleted INTEGER NOT NULL DEFAULT 0);');
      raw.execute(
          'CREATE VIRTUAL TABLE user_search USING fts5(type UNINDEXED, reference_id UNINDEXED, text_content);');
      raw.execute('PRAGMA user_version = 1;');
      raw.close();

      // Before the fix, onUpgrade(1 -> 21) fell through from the destructive
      // v2 block into the v7 block and threw "duplicate column name:
      // selected_verses". It must now wipe to the current schema and stop.
      final store = UserStore(NativeDatabase(file));
      await store.customSelect('SELECT 1').get(); // force the lazy open + migrate

      // A current-schema table (added long after v1) exists, and the FTS
      // triggers are installed.
      final hasJournals = await store
          .customSelect(
              "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'journals'")
          .get();
      expect(hasJournals, isNotEmpty);
      final hasTrigger = await store
          .customSelect(
              "SELECT 1 FROM sqlite_master WHERE type = 'trigger' AND name = 'notes_ai'")
          .get();
      expect(hasTrigger, isNotEmpty);

      await store.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
