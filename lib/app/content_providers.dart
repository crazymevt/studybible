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
  return (store.select(store.books)..where((b) => b.versionId.equals(versionId))).get();
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
