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
}
