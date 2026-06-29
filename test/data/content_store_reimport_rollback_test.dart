import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';

/// The content manager wraps a module reimport (delete-then-insert) in a single
/// `store.transaction`, so a mid-import failure rolls back and leaves the
/// previously-installed module intact instead of half-deleted. These tests
/// exercise that transactional guarantee directly against the store.
void main() {
  late ContentStore store;

  setUp(() {
    store = ContentStore(NativeDatabase.memory());
  });

  tearDown(() async {
    await store.close();
  });

  Future<void> installVersion(String id, String verseText) async {
    await store.into(store.versions).insert(
          VersionsCompanion.insert(id: id, abbreviation: id, name: id),
          mode: InsertMode.insertOrReplace,
        );
    final bookId = await store.into(store.books).insert(
          BooksCompanion.insert(
            versionId: id,
            name: 'Genesis',
            bookOrder: 1,
            testament: 'OT',
          ),
        );
    await store.into(store.verses).insert(
          VersesCompanion.insert(
            bookId: bookId,
            chapter: 1,
            verse: 1,
            textContent: verseText,
            segments: '[]',
          ),
        );
  }

  Future<String?> verseText(String versionId) async {
    final row = await store
        .customSelect(
          'SELECT v.text_content AS t FROM verses v '
          'JOIN books b ON v.book_id = b.id WHERE b.version_id = ?',
          variables: [Variable.withString(versionId)],
        )
        .getSingleOrNull();
    return row?.read<String>('t');
  }

  test('a reimport that throws mid-transaction leaves the old module intact',
      () async {
    await installVersion('AV', 'original text');

    // Simulate the provider's atomic reimport: delete the old copy, begin
    // re-inserting, then fail before completing.
    await expectLater(
      store.transaction(() async {
        await store.deleteVersion('AV');
        await installVersion('AV', 'new text');
        throw Exception('import failed partway');
      }),
      throwsA(isA<Exception>()),
    );

    // The whole transaction rolled back: the original module survives.
    expect(await verseText('AV'), 'original text');
  });

  test('a reimport that completes replaces the old module', () async {
    await installVersion('AV', 'original text');

    await store.transaction(() async {
      await store.deleteVersion('AV');
      await installVersion('AV', 'new text');
    });

    expect(await verseText('AV'), 'new text');
  });
}
