import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:study_bible/data/content_store.dart';
import '../data/user_store.dart';
import 'app_state.dart';
import 'reader_state.dart';
import 'user_providers.dart';
import 'sync_service.dart';
import 'dart:async';
import 'package:collection/collection.dart';

import '../data/importer/cross_reference_importer.dart';
import 'package:flutter/widgets.dart';

// Guards the one-time cross-reference import so it is scheduled at most once
// per process, even if this provider is rebuilt — two concurrent imports race
// on the database and the shared temp file.
bool _crossRefImportStarted = false;

final contentStoreProvider = Provider<ContentStore>((ref) {
  final store = ContentStore();

  // Close the underlying connection (and its background isolate) when the
  // provider is disposed, so a recreated app/engine never opens a second
  // connection to the same WAL database and deadlocks it.
  ref.onDispose(() => store.close());

  // Defer the (potentially large) first-install cross-reference import until
  // after the first frame so it doesn't contend with startup DB access.
  if (!_crossRefImportStarted) {
    _crossRefImportStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final importer = CrossReferenceImporter(store);
        await importer.importIfEmpty();
      } catch (e) {
        debugPrint('Failed to import cross references: $e');
      }
    });
  }

  return store;
});

final versionsProvider = FutureProvider<List<Version>>((ref) {
  final store = ref.watch(contentStoreProvider);
  return store.select(store.versions).get();
});

final installedModuleIdsProvider = FutureProvider<Set<String>>((ref) async {
  final store = ref.watch(contentStoreProvider);
  
  final versions = await store.select(store.versions).get();
  final commentaries = await store.select(store.commentaries).get();
  final dictionaries = await store.select(store.dictionaries).get();
  final devotionals = await store.select(store.devotionals).get();
  
  final set = <String>{};
  for (final v in versions) {
    set.add(v.id.toUpperCase());
    set.add(v.abbreviation.toUpperCase());
  }
  for (final c in commentaries) {
    set.add(c.abbreviation.toUpperCase());
  }
  for (final d in dictionaries) {
    set.add(d.abbreviation.toUpperCase());
  }
  for (final dv in devotionals) {
    set.add(dv.abbreviation.toUpperCase());
  }
  return set;
});

final bibleVersionsProvider = FutureProvider<List<Version>>((ref) async {
  final store = ref.watch(contentStoreProvider);
  final allVersions = await store.select(store.versions).get();
  final bookVersions = await store.customSelect('SELECT DISTINCT version_id FROM books').get();
  final bookVersionIds = bookVersions.map((row) => row.read<String>('version_id')).toSet();
  
  return allVersions.where((v) => bookVersionIds.contains(v.id)).toList();
});

final subheadingSourcesProvider = FutureProvider<List<Version>>((ref) async {
  final store = ref.watch(contentStoreProvider);
  final allVersions = await store.select(store.versions).get();
  final shVersions = await store.customSelect('SELECT DISTINCT version_id FROM subheadings').get();
  final shVersionIds = shVersions.map((row) => row.read<String>('version_id')).toSet();
  
  return allVersions.where((v) => shVersionIds.contains(v.id)).toList();
});

final booksForVersionProvider = FutureProvider.family<List<Book>, String>((
  ref,
  versionId,
) {
  final store = ref.watch(contentStoreProvider);
  return (store.select(store.books)
        ..where((b) => b.versionId.equals(versionId))
        ..orderBy([(b) => OrderingTerm.asc(b.bookOrder)]))
      .get();
});

final chapterCountProvider = FutureProvider.family<int, int>((
  ref,
  bookId,
) async {
  final store = ref.watch(contentStoreProvider);
  final maxChapterExpr = store.verses.chapter.max();
  final query = store.selectOnly(store.verses)
    ..addColumns([maxChapterExpr])
    ..where(store.verses.bookId.equals(bookId));

  final result = await query.getSingle();
  return result.read(maxChapterExpr) ?? 1;
});

final versesForChapterProvider =
    FutureProvider.family<List<Verse>, ({int bookId, int chapter})>((
      ref,
      args,
    ) {
      final store = ref.watch(contentStoreProvider);
      return (store.select(store.verses)..where(
            (v) =>
                v.bookId.equals(args.bookId) & v.chapter.equals(args.chapter),
          ))
          .get();
    });

final bookByNameProvider =
    FutureProvider.family<Book?, ({String versionId, String name})>((
      ref,
      args,
    ) async {
      final books = await ref.watch(
        booksForVersionProvider(args.versionId).future,
      );
      return books.where((b) {
        final bName = b.name.toLowerCase();
        final aName = args.name.toLowerCase();
        if (bName == aName) return true;
        if (bName == '${aName}s') return true;
        if ('${bName}s' == aName) return true;
        return false;
      }).firstOrNull;
    });

final chapterSubheadingsProvider = FutureProvider.family<Map<int, List<String>>, ({String bookName, int chapter})>((ref, args) async {
  final sourceVersionId = ref.watch(subheadingsSourceProvider);
  if (sourceVersionId == null || sourceVersionId.isEmpty) {
    return {};
  }
  
  final activeVersions = ref.watch(activeVersionsProvider);
  if (activeVersions.isEmpty) return {};
  
  final primaryBibleId = activeVersions.first;
  final book = await ref.watch(bookByNameProvider((versionId: primaryBibleId, name: args.bookName)).future);
  if (book == null) return {};
  
  final store = ref.watch(contentStoreProvider);
  final query = store.select(store.subheadings)
    ..where((s) => s.versionId.equals(sourceVersionId))
    ..where((s) => s.bookOrder.equals(book.bookOrder))
    ..where((s) => s.chapter.equals(args.chapter))
    ..orderBy([(s) => OrderingTerm(expression: s.verse), (s) => OrderingTerm(expression: s.orderIfSeveral)]);
    
  final results = await query.get();
  
  final map = <int, List<String>>{};
  for (final row in results) {
    map.putIfAbsent(row.verse, () => []).add(row.textContent);
  }
  return map;
});

final validActiveVersionsProvider = FutureProvider<List<String>>((ref) async {
  final activeVersions = ref.watch(activeVersionsProvider);
  final installedVersions = await ref.watch(versionsProvider.future);

  if (installedVersions.isEmpty) return [];

  final valid = activeVersions
      .where((av) => installedVersions.any((iv) => iv.id == av))
      .toList();

  List<String> finalVersions = valid;
  if (valid.isEmpty) {
    finalVersions = [installedVersions.first.id];
  }

  if (finalVersions.length != activeVersions.length ||
      !const IterableEquality().equals(finalVersions, activeVersions)) {
    Future.microtask(() {
      if (ref.exists(activeVersionsProvider)) {
        ref.read(activeVersionsProvider.notifier).set(finalVersions);
      }
    });
  }

  return finalVersions;
});

final parallelVersesProvider = FutureProvider<Map<String, List<Verse>>>((
  ref,
) async {
  final versions = await ref.watch(validActiveVersionsProvider.future);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);

  final map = <String, List<Verse>>{};
  for (final versionId in versions) {
    final book = await ref.watch(
      bookByNameProvider((versionId: versionId, name: bookName)).future,
    );
    if (book != null) {
      final verses = await ref.watch(
        versesForChapterProvider((bookId: book.id, chapter: chapter)).future,
      );
      map[versionId] = verses;
    } else {
      map[versionId] = [];
    }
  }
  return map;
});

class CompareResult {
  final Version version;
  final List<Verse> verses;
  CompareResult({required this.version, required this.verses});
}

final compareVersesProvider = FutureProvider.family<List<CompareResult>, ({String bookName, int chapter, String selectedVersesStr})>((ref, args) async {
  final versions = await ref.watch(versionsProvider.future);
  final results = <CompareResult>[];
  final contentStore = ref.watch(contentStoreProvider);

  final selectedVerses = args.selectedVersesStr.split(',').map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();

  for (final v in versions) {
    final book = await ref.watch(bookByNameProvider((versionId: v.id, name: args.bookName)).future);
    if (book != null) {
      final verses = await (contentStore.select(contentStore.verses)
            ..where((t) =>
                t.bookId.equals(book.id) &
                t.chapter.equals(args.chapter) &
                t.verse.isIn(selectedVerses))
            ..orderBy([(t) => OrderingTerm.asc(t.verse)]))
          .get();

      if (verses.isNotEmpty) {
        results.add(CompareResult(version: v, verses: verses));
      }
    }
  }
  return results;
});

final crossReferencesProvider =
    FutureProvider.family<List<CrossReference>, int>((ref, verse) {
      final store = ref.watch(contentStoreProvider);
      final bookName = ref.watch(selectedBookNameProvider);
      final chapter = ref.watch(selectedChapterProvider);

      return (store.select(store.crossReferences)
            ..where(
              (c) =>
                  (c.sourceBookName.equals(bookName)) &
                  (c.sourceChapter.equals(chapter)) &
                  (c.sourceVerse.equals(verse)),
            )
            ..orderBy([
              (c) =>
                  drift.OrderingTerm(expression: c.votes, mode: drift.OrderingMode.desc)
            ]))
          .get();
    });

final crossReferenceVerseProvider =
    FutureProvider.family<Verse?, CrossReference>((ref, xref) async {
      final versions = ref.watch(activeVersionsProvider);
      if (versions.isEmpty) return null;
      final versionId = versions.first; // Primary version

      final book = await ref.watch(
        bookByNameProvider((
          versionId: versionId,
          name: xref.targetBookName,
        )).future,
      );
      if (book == null) return null;

      final store = ref.watch(contentStoreProvider);
      return (store.select(store.verses)..where(
            (v) =>
                (v.bookId.equals(book.id)) &
                (v.chapter.equals(xref.targetChapter)) &
                (v.verse.equals(xref.targetVerse)),
          ))
          .getSingleOrNull();
    });

final navigationControllerProvider = Provider(
  (ref) => NavigationController(ref),
);

final commentariesProvider = FutureProvider<List<Commentary>>((ref) {
  final store = ref.watch(contentStoreProvider);
  return store.select(store.commentaries).get();
});

final dictionariesProvider = FutureProvider<List<Dictionary>>((ref) {
  final store = ref.watch(contentStoreProvider);
  return store.select(store.dictionaries).get();
});

final devotionalsProvider = FutureProvider<List<Devotional>>((ref) {
  final store = ref.watch(contentStoreProvider);
  return store.select(store.devotionals).get();
});

class ShowBookIntroNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

final showBookIntroProvider = NotifierProvider<ShowBookIntroNotifier, bool>(
  () => ShowBookIntroNotifier(),
);

final hasBookIntroProvider = FutureProvider<bool>((ref) async {
  final store = ref.watch(contentStoreProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final selectedCommentaryId = ref.watch(selectedCommentaryProvider);
  
  if (selectedCommentaryId == null) return false;
  
  final countExp = store.commentaryEntries.id.count();
  final query = store.selectOnly(store.commentaryEntries)
    ..addColumns([countExp])
    ..where(store.commentaryEntries.commentaryId.equals(selectedCommentaryId) &
            store.commentaryEntries.bookName.equals(bookName) &
            (store.commentaryEntries.chapter.equals(0) | store.commentaryEntries.chapter.isNull()));
            
  final result = await query.getSingle();
  return (result.read(countExp) ?? 0) > 0;
});

final commentaryEntriesProvider = FutureProvider<List<CommentaryEntry>>((
  ref,
) async {
  final store = ref.watch(contentStoreProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);
  final selectedVerses = ref.watch(selectedVersesProvider);
  final showIntro = ref.watch(showBookIntroProvider);
  final selectedCommentaryId = ref.watch(selectedCommentaryProvider);

  if (selectedCommentaryId == null) return [];

  if (showIntro) {
    return (store.select(store.commentaryEntries)..where(
          (c) =>
              c.commentaryId.equals(selectedCommentaryId) &
              c.bookName.equals(bookName) &
              (c.chapter.equals(0) | c.chapter.isNull()),
        ))
        .get();
  }

  if (selectedVerses.isNotEmpty) {
    return (store.select(store.commentaryEntries)
          ..where(
            (c) =>
                c.bookName.equals(bookName) &
                c.chapter.equals(chapter) &
                c.verse.isIn(selectedVerses),
          )
          ..orderBy([
            (c) => OrderingTerm.asc(c.verse),
            (c) => OrderingTerm.asc(c.commentaryId)
          ]))
        .get();
  } else {
    // Show all commentaries for the chapter
    return (store.select(store.commentaryEntries)
          ..where(
            (c) =>
                c.commentaryId.equals(selectedCommentaryId) &
                c.bookName.equals(bookName) &
                c.chapter.equals(chapter),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.verse)]))
        .get();
  }
});

class DictionaryEntryWithDict {
  final DictionaryEntry entry;
  final Dictionary dictionary;
  DictionaryEntryWithDict({required this.entry, required this.dictionary});
}

class DictionarySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final dictionarySearchQueryProvider =
    NotifierProvider<DictionarySearchQueryNotifier, String>(
      () => DictionarySearchQueryNotifier(),
    );

final dictionaryEntriesProvider = FutureProvider<List<DictionaryEntryWithDict>>(
  (ref) async {
    final store = ref.watch(contentStoreProvider);
    final query = ref.watch(dictionarySearchQueryProvider);
    if (query.trim().isEmpty) return [];

    final search = '%${query.trim()}%';

    final q = store.select(store.dictionaryEntries).join([
      innerJoin(
        store.dictionaries,
        store.dictionaries.id.equalsExp(store.dictionaryEntries.dictionaryId),
      ),
    ])..where(store.dictionaryEntries.word.like(search));

    final results = await q.get();
    return results.map((row) {
      return DictionaryEntryWithDict(
        entry: row.readTable(store.dictionaryEntries),
        dictionary: row.readTable(store.dictionaries),
      );
    }).toList();
  },
);

class NavigationController {
  final Ref ref;
  NavigationController(this.ref);

  Future<void> recordHistory({int? verse}) async {
    final store = ref.read(contentStoreProvider);
    final userStore = ref.read(userStoreProvider);
    final bookName = ref.read(selectedBookNameProvider);
    final chapter = ref.read(selectedChapterProvider);
    final activeVersions = ref.read(activeVersionsProvider);

    String? verseText;

    // Only query text if a verse was explicitly provided and we have versions
    if (verse != null && activeVersions.isNotEmpty) {
      final versionId = activeVersions.first;
      final book = await ref.read(
        bookByNameProvider((versionId: versionId, name: bookName)).future,
      );
      if (book != null) {
        final v =
            await (store.select(store.verses)..where(
                  (v) =>
                      v.bookId.equals(book.id) &
                      v.chapter.equals(chapter) &
                      v.verse.equals(verse),
                ))
                .getSingleOrNull();
        if (v != null) {
          verseText = v.textContent;
        }
      }
    }

    final deviceId = await ref.read(deviceIdProvider.future);

    // Remove any existing entry with the same book/chapter/verse combo
    // so we don't get duplicates — the new entry becomes the most recent.
    final existingQuery = userStore.select(userStore.navigationHistories)
      ..where(
        (h) =>
            h.bookName.equals(bookName) &
            h.chapter.equals(chapter) &
            h.deleted.equals(false),
      );
    if (verse != null) {
      existingQuery.where((h) => h.verse.equals(verse));
    } else {
      existingQuery.where((h) => h.verse.isNull());
    }
    final existing = await existingQuery.get();
    for (final old in existing) {
      await userStore
          .into(userStore.navigationHistories)
          .insert(
            old.copyWith(
              deleted: true,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
            mode: InsertMode.replace,
          );
    }

    final newEntry = NavigationHistory(
      id: const Uuid().v4(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      deviceId: deviceId,
      deleted: false,
      bookName: bookName,
      chapter: chapter,
      verse: verse,
      verseText: verseText,
    );

    await userStore.into(userStore.navigationHistories).insert(newEntry);
  }

  void navigateTo({required String bookName, required int chapter}) {
    ref.read(selectedBookNameProvider.notifier).set(bookName);
    ref.read(selectedChapterProvider.notifier).set(chapter);
    recordHistory();
  }

  Future<void> nextChapter() async {
    final activeVersions = ref.read(activeVersionsProvider);
    if (activeVersions.isEmpty) return;

    final versionId = activeVersions.first;
    final books = await ref.read(booksForVersionProvider(versionId).future);

    final currentBookName = ref.read(selectedBookNameProvider);
    final currentChapter = ref.read(selectedChapterProvider);

    final bookIndex = books.indexWhere((b) => b.name == currentBookName);
    if (bookIndex == -1) return;

    final currentBook = books[bookIndex];
    final maxChapter = await ref.read(
      chapterCountProvider(currentBook.id).future,
    );

    if (currentChapter < maxChapter) {
      ref.read(selectedChapterProvider.notifier).set(currentChapter + 1);
    } else if (bookIndex + 1 < books.length) {
      ref
          .read(selectedBookNameProvider.notifier)
          .set(books[bookIndex + 1].name);
      ref.read(selectedChapterProvider.notifier).set(1);
    }

    // Only record chapter history
    recordHistory();
  }

  Future<void> previousChapter() async {
    final activeVersions = ref.read(activeVersionsProvider);
    if (activeVersions.isEmpty) return;

    final versionId = activeVersions.first;
    final books = await ref.read(booksForVersionProvider(versionId).future);

    final currentBookName = ref.read(selectedBookNameProvider);
    final currentChapter = ref.read(selectedChapterProvider);

    final bookIndex = books.indexWhere((b) => b.name == currentBookName);
    if (bookIndex == -1) return;

    if (currentChapter > 1) {
      ref.read(selectedChapterProvider.notifier).set(currentChapter - 1);
    } else if (bookIndex > 0) {
      final prevBook = books[bookIndex - 1];
      final maxChapter = await ref.read(
        chapterCountProvider(prevBook.id).future,
      );
      ref.read(selectedBookNameProvider.notifier).set(prevBook.name);
      ref.read(selectedChapterProvider.notifier).set(maxChapter);
    }

    // Only record chapter history
    recordHistory();
  }
}
