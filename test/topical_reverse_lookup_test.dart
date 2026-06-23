import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/topic_providers.dart';

/// Exercises the topical reverse lookup (verse -> topics) across the three ref
/// shapes the importer produces: whole-chapter, single-verse, and verse-range.
void main() {
  late ContentStore store;
  late ProviderContainer container;

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());

    // FAITH: a verse range John 11:25-27.
    await store.into(store.topics).insert(
        const TopicsCompanion(id: Value(1), name: Value('FAITH'), section: Value('F')));
    await store.into(store.topicEntries).insert(const TopicEntriesCompanion(
        id: Value(1),
        topicId: Value(1),
        ordinal: Value(1),
        description: Value('General')));
    await store.into(store.topicReferences).insert(const TopicReferencesCompanion(
        id: Value(1),
        topicId: Value(1),
        entryId: Value(1),
        bookName: Value('John'),
        chapter: Value(11),
        verse: Value(25),
        verseEnd: Value(27)));

    // MIRACLES: a whole chapter John 11 (verse null).
    await store.into(store.topics).insert(
        const TopicsCompanion(id: Value(2), name: Value('MIRACLES'), section: Value('M')));
    await store.into(store.topicEntries).insert(const TopicEntriesCompanion(
        id: Value(2),
        topicId: Value(2),
        ordinal: Value(1),
        description: Value('Catalogue')));
    await store.into(store.topicReferences).insert(const TopicReferencesCompanion(
        id: Value(2),
        topicId: Value(2),
        entryId: Value(2),
        bookName: Value('John'),
        chapter: Value(11),
        verse: Value(null),
        verseEnd: Value(null)));

    // OTHER: a single verse John 11:40.
    await store.into(store.topics).insert(
        const TopicsCompanion(id: Value(3), name: Value('OTHER'), section: Value('O')));
    await store.into(store.topicEntries).insert(const TopicEntriesCompanion(
        id: Value(3),
        topicId: Value(3),
        ordinal: Value(1),
        description: Value('Misc')));
    await store.into(store.topicReferences).insert(const TopicReferencesCompanion(
        id: Value(3),
        topicId: Value(3),
        entryId: Value(3),
        bookName: Value('John'),
        chapter: Value(11),
        verse: Value(40),
        verseEnd: Value(null)));

    container = ProviderContainer(overrides: [
      contentStoreProvider.overrideWithValue(store),
      // Skip the asset-loading step; rows are seeded directly above.
      topicalIndexReadyProvider.overrideWith((ref) async => true),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  Future<Set<String>> topicsFor(int verse) async {
    final list = await container.read(
      topicsForVerseProvider((book: 'John', chapter: 11, verse: verse)).future,
    );
    return list.map((t) => t.topicName).toSet();
  }

  test('verse 25 matches the range (FAITH) and the whole chapter (MIRACLES)',
      () async {
    expect(await topicsFor(25), {'FAITH', 'MIRACLES'});
  });

  test('verse 40 matches the single verse (OTHER) and whole chapter, not the range',
      () async {
    expect(await topicsFor(40), {'MIRACLES', 'OTHER'});
  });

  test('a verse referenced only by the whole chapter still matches', () async {
    expect(await topicsFor(1), {'MIRACLES'});
  });

  test('a different book does not match', () async {
    final list = await container.read(
      topicsForVerseProvider((book: 'Acts', chapter: 11, verse: 25)).future,
    );
    expect(list, isEmpty);
  });
}
