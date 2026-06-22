import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';

void main() {
  late ContentStore store;

  setUp(() {
    store = ContentStore(NativeDatabase.memory());
  });

  tearDown(() async {
    await store.close();
  });

  Future<Set<String>> vocab() async {
    final rows =
        await store.customSelect('SELECT term FROM content_vocab').get();
    return rows.map((r) => r.read<String>('term')).toSet();
  }

  test('onCreate provides content_vocab for word autocomplete', () async {
    // Should not throw — the table exists on a fresh database.
    expect(await vocab(), isEmpty);
  });

  test('indexStrippedEntries strips markup from commentary HTML', () async {
    final commentaryId = await store.into(store.commentaries).insert(
          CommentariesCompanion.insert(abbreviation: 'X', name: 'X Commentary'),
        );
    final entryId = await store.into(store.commentaryEntries).insert(
          CommentaryEntriesCompanion.insert(
            commentaryId: commentaryId,
            bookName: 'John',
            textContent: '<div id="jessdvffhtl1t1cputsp">Grace abounds</div>',
          ),
        );
    expect(entryId, greaterThan(0));

    await store.indexStrippedEntries(
        'commentary', 'commentary_entries', 'commentary_id', commentaryId);

    final terms = await vocab();
    expect(terms, containsAll(<String>['grace', 'abounds']));
    expect(terms, isNot(contains('jessdvffhtl1t1cputsp')));
    expect(terms, isNot(contains('div')));
  });

  test('rebuildSearchIndex cleans an index that holds raw HTML', () async {
    final commentaryId = await store.into(store.commentaries).insert(
          CommentariesCompanion.insert(abbreviation: 'Y', name: 'Y Commentary'),
        );
    final entryId = await store.into(store.commentaryEntries).insert(
          CommentaryEntriesCompanion.insert(
            commentaryId: commentaryId,
            bookName: 'John',
            textContent: '<span class="zzjunk">Mercy</span>',
          ),
        );

    // Simulate a pre-strip index by inserting the raw HTML directly.
    await store.customStatement(
      "INSERT INTO content_search(type, reference_id, text_content) "
      "VALUES ('commentary', ?, ?)",
      [entryId, '<span class="zzjunk">Mercy</span>'],
    );
    expect(await vocab(), contains('zzjunk'));

    await store.rebuildSearchIndex();

    final terms = await vocab();
    expect(terms, contains('mercy'));
    expect(terms, isNot(contains('zzjunk')));
    expect(terms, isNot(contains('span')));
  });
}
