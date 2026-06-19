import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:study_bible/data/content_store.dart';
import 'reader_state.dart';

final contentStoreProvider = Provider<ContentStore>((ref) {
  return ContentStore();
});

final versionsProvider = FutureProvider<List<Version>>((ref) {
  final store = ref.watch(contentStoreProvider);
  return store.select(store.versions).get();
});

final booksForVersionProvider = FutureProvider.family<List<Book>, String>((ref, versionId) {
  final store = ref.watch(contentStoreProvider);
  return (store.select(store.books)
        ..where((b) => b.versionId.equals(versionId))
        ..orderBy([(b) => OrderingTerm.asc(b.bookOrder)]))
      .get();
});

final chapterCountProvider = FutureProvider.family<int, int>((ref, bookId) async {
  final store = ref.watch(contentStoreProvider);
  final maxChapterExpr = store.verses.chapter.max();
  final query = store.selectOnly(store.verses)
    ..addColumns([maxChapterExpr])
    ..where(store.verses.bookId.equals(bookId));
  
  final result = await query.getSingle();
  return result.read(maxChapterExpr) ?? 1;
});

final versesForChapterProvider = FutureProvider.family<List<Verse>, ({int bookId, int chapter})>((ref, args) {
  final store = ref.watch(contentStoreProvider);
  return (store.select(store.verses)..where((v) => v.bookId.equals(args.bookId) & v.chapter.equals(args.chapter))).get();
});

final bookByNameProvider = FutureProvider.family<Book?, ({String versionId, String name})>((ref, args) async {
  final books = await ref.watch(booksForVersionProvider(args.versionId).future);
  return books.where((b) => b.name == args.name).firstOrNull;
});

final parallelVersesProvider = FutureProvider<Map<String, List<Verse>>>((ref) async {
  final versions = ref.watch(activeVersionsProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);

  final map = <String, List<Verse>>{};
  for (final versionId in versions) {
    final book = await ref.watch(bookByNameProvider((versionId: versionId, name: bookName)).future);
    if (book != null) {
      final verses = await ref.watch(versesForChapterProvider((bookId: book.id, chapter: chapter)).future);
      map[versionId] = verses;
    } else {
      map[versionId] = [];
    }
  }
  return map;
});

final crossReferencesProvider = FutureProvider.family<List<CrossReference>, int>((ref, verse) {
  final store = ref.watch(contentStoreProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);

  return (store.select(store.crossReferences)
        ..where((c) => (c.sourceBookName.equals(bookName)) & (c.sourceChapter.equals(chapter)) & (c.sourceVerse.equals(verse))))
      .get();
});

final crossReferenceVerseProvider = FutureProvider.family<Verse?, CrossReference>((ref, xref) async {
  final versions = ref.watch(activeVersionsProvider);
  if (versions.isEmpty) return null;
  final versionId = versions.first; // Primary version

  final book = await ref.watch(bookByNameProvider((versionId: versionId, name: xref.targetBookName)).future);
  if (book == null) return null;

  final store = ref.watch(contentStoreProvider);
  return (store.select(store.verses)
        ..where((v) => (v.bookId.equals(book.id)) & (v.chapter.equals(xref.targetChapter)) & (v.verse.equals(xref.targetVerse))))
      .getSingleOrNull();
});

final navigationControllerProvider = Provider((ref) => NavigationController(ref));

final commentariesProvider = FutureProvider<List<Commentary>>((ref) {
  final store = ref.watch(contentStoreProvider);
  return store.select(store.commentaries).get();
});

class ShowBookIntroNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

final showBookIntroProvider = NotifierProvider<ShowBookIntroNotifier, bool>(() => ShowBookIntroNotifier());

final commentaryEntriesProvider = FutureProvider<List<CommentaryEntry>>((ref) async {
  final store = ref.watch(contentStoreProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);
  final selectedVerses = ref.watch(selectedVersesProvider);
  final showIntro = ref.watch(showBookIntroProvider);

  if (showIntro) {
    return (store.select(store.commentaryEntries)
          ..where((c) => c.bookName.equals(bookName) & c.chapter.isNull()))
        .get();
  }

  if (selectedVerses.isNotEmpty) {
    return (store.select(store.commentaryEntries)
          ..where((c) => c.bookName.equals(bookName) & c.chapter.equals(chapter) & c.verse.isIn(selectedVerses)))
        .get();
  } else {
    // Show all commentaries for the chapter
    return (store.select(store.commentaryEntries)
          ..where((c) => c.bookName.equals(bookName) & c.chapter.equals(chapter)))
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

final dictionarySearchQueryProvider = NotifierProvider<DictionarySearchQueryNotifier, String>(() => DictionarySearchQueryNotifier());

final dictionaryEntriesProvider = FutureProvider<List<DictionaryEntryWithDict>>((ref) async {
  final store = ref.watch(contentStoreProvider);
  final query = ref.watch(dictionarySearchQueryProvider);
  if (query.trim().isEmpty) return [];

  final search = '%${query.trim()}%';

  final q = store.select(store.dictionaryEntries).join([
    innerJoin(store.dictionaries, store.dictionaries.id.equalsExp(store.dictionaryEntries.dictionaryId)),
  ])
  ..where(store.dictionaryEntries.word.like(search));

  final results = await q.get();
  return results.map((row) {
    return DictionaryEntryWithDict(
      entry: row.readTable(store.dictionaryEntries),
      dictionary: row.readTable(store.dictionaries),
    );
  }).toList();
});

class NavigationController {
  final Ref ref;
  NavigationController(this.ref);

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
    final maxChapter = await ref.read(chapterCountProvider(currentBook.id).future);
    
    if (currentChapter < maxChapter) {
      ref.read(selectedChapterProvider.notifier).set(currentChapter + 1);
    } else if (bookIndex + 1 < books.length) {
      ref.read(selectedBookNameProvider.notifier).set(books[bookIndex + 1].name);
      ref.read(selectedChapterProvider.notifier).set(1);
    }
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
      final maxChapter = await ref.read(chapterCountProvider(prevBook.id).future);
      ref.read(selectedBookNameProvider.notifier).set(prevBook.name);
      ref.read(selectedChapterProvider.notifier).set(maxChapter);
    }
  }
}
