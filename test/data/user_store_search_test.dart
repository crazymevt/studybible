import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/fts_text.dart';
import 'package:study_bible/data/user_store.dart';

void main() {
  late UserStore store;

  setUp(() {
    store = UserStore(NativeDatabase.memory());
  });

  tearDown(() async {
    await store.close();
  });

  test('sermon search index uses plain text, not Delta JSON', () async {
    const delta =
        '[{"insert":"Grace and "},{"insert":"truth","attributes":{"bold":true}},{"insert":"\\n"}]';

    await store.into(store.sermons).insert(
          SermonsCompanion.insert(
            id: 's1',
            createdAt: 0,
            updatedAt: 0,
            deviceId: 'device',
            title: 'My Sermon',
            series: const Value('Series A'),
            content: delta,
            contentPlain: Value(deltaToPlainText(delta)),
          ),
        );

    final rows = await store
        .customSelect("SELECT text_content AS t FROM user_search WHERE type='sermon'")
        .get();
    final indexed = rows.map((r) => r.read<String>('t')).join(' ');

    // Real words are searchable...
    expect(indexed, contains('Grace'));
    expect(indexed, contains('truth'));
    expect(indexed, contains('My Sermon'));
    // ...but Delta JSON structure is not indexed.
    expect(indexed, isNot(contains('insert')));
    expect(indexed, isNot(contains('attributes')));
    expect(indexed, isNot(contains('bold')));
  });

  Future<int> noteCount(UserStore s, String id) async {
    final rows = await s
        .customSelect(
          "SELECT COUNT(*) AS c FROM user_search WHERE type='note' AND reference_id='$id'",
        )
        .get();
    return rows.first.read<int>('c');
  }

  test('soft-deleting a note via INSERT OR REPLACE removes it from the index',
      () async {
    await store.into(store.notes).insert(
          NotesCompanion.insert(
            id: 'n1',
            updatedAt: 0,
            deviceId: 'device',
            bookName: 'John',
            chapter: 3,
            content: 'amazing grace',
          ),
        );
    expect(await noteCount(store, 'n1'), 1);

    // Mirror how sync/save writes: a full-row INSERT OR REPLACE that flips the
    // soft-delete flag. REPLACE's implicit row delete does not fire the AFTER
    // DELETE trigger (recursive_triggers is off), so the INSERT/UPDATE trigger
    // must clear the stale index row itself.
    await store.into(store.notes).insert(
          NotesCompanion.insert(
            id: 'n1',
            updatedAt: 1,
            deviceId: 'device',
            bookName: 'John',
            chapter: 3,
            content: 'amazing grace',
            deleted: const Value(true),
          ),
          mode: InsertMode.replace,
        );

    expect(await noteCount(store, 'n1'), 0,
        reason: 'soft-deleted note should not leak into the search index');
  });

  test('restoring a soft-deleted note via REPLACE re-indexes it once',
      () async {
    await store.into(store.notes).insert(
          NotesCompanion.insert(
            id: 'n2',
            updatedAt: 0,
            deviceId: 'device',
            bookName: 'Acts',
            chapter: 2,
            content: 'pentecost',
            deleted: const Value(true),
          ),
        );
    expect(await noteCount(store, 'n2'), 0);

    await store.into(store.notes).insert(
          NotesCompanion.insert(
            id: 'n2',
            updatedAt: 1,
            deviceId: 'device',
            bookName: 'Acts',
            chapter: 2,
            content: 'pentecost',
            deleted: const Value(false),
          ),
          mode: InsertMode.replace,
        );

    expect(await noteCount(store, 'n2'), 1,
        reason: 'restored note should be re-indexed exactly once');
  });
}
