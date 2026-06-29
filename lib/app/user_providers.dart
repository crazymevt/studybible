import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../data/user_store.dart';
import 'reader_state.dart';
import 'sync_service.dart';
import 'achievement_service.dart';
import 'tag_providers.dart';

final userStoreProvider = Provider<UserStore>((ref) {
  final store = UserStore();
  // Close the connection (and its background isolate) on dispose so a recreated
  // app/engine can't open a second connection to the same WAL database.
  ref.onDispose(() => store.close());
  return store;
});

// A stream provider that emits the Map of highlighted verses for the current book/chapter.
final chapterHighlightsFamilyProvider = StreamProvider.family<Map<int, String>,
    ({String bookName, int chapter})>((ref, args) {
  final store = ref.watch(userStoreProvider);

  return (store.select(store.highlights)..where(
        (h) =>
            (h.bookName.equals(args.bookName)) &
            (h.chapter.equals(args.chapter)) &
            (h.deleted.equals(false)),
      ))
      .watch()
      .map((highlights) => {for (var h in highlights) h.verse: h.colorHex});
});

/// Highlights for the currently-selected chapter. Delegates to
/// [chapterHighlightsFamilyProvider] so the reader's swipe pages can each load
/// their own chapter's highlights.
final chapterHighlightsProvider =
    Provider<AsyncValue<Map<int, String>>>((ref) {
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);
  return ref.watch(
    chapterHighlightsFamilyProvider((bookName: bookName, chapter: chapter)),
  );
});

final highlightActionProvider = Provider((ref) {
  return HighlightAction(ref);
});

class HighlightAction {
  final Ref ref;
  HighlightAction(this.ref);

  Future<void> applyHighlight(int verse, String colorHex) async {
    final store = ref.read(userStoreProvider);
    final bookName = ref.read(selectedBookNameProvider);
    final chapter = ref.read(selectedChapterProvider);
    final deviceId = await ref.read(deviceIdProvider.future);

    final existing =
        await (store.select(store.highlights)..where(
              (h) =>
                  (h.bookName.equals(bookName)) &
                  (h.chapter.equals(chapter)) &
                  (h.verse.equals(verse)) &
                  (h.deleted.equals(false)),
            ))
            .getSingleOrNull();

    if (existing != null) {
      if (existing.colorHex == colorHex) {
        // Toggle off if same color
        await store
            .into(store.highlights)
            .insert(
              existing.copyWith(
                deleted: true,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              ),
              mode: InsertMode.replace,
            );
      } else {
        // Change color
        await store
            .into(store.highlights)
            .insert(
              existing.copyWith(
                colorHex: colorHex,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              ),
              mode: InsertMode.replace,
            );
      }
    } else {
      final newHighlight = Highlight(
        id: const Uuid().v4(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: deviceId,
        deleted: false,
        bookName: bookName,
        chapter: chapter,
        verse: verse,
        colorHex: colorHex,
      );
      await store.into(store.highlights).insert(newHighlight);
    }
    ref.read(achievementServiceProvider).evaluateAchievements();
  }

  Future<void> clearHighlight(int verse) async {
    final store = ref.read(userStoreProvider);
    final bookName = ref.read(selectedBookNameProvider);
    final chapter = ref.read(selectedChapterProvider);

    final existing =
        await (store.select(store.highlights)..where(
              (h) =>
                  (h.bookName.equals(bookName)) &
                  (h.chapter.equals(chapter)) &
                  (h.verse.equals(verse)) &
                  (h.deleted.equals(false)),
            ))
            .getSingleOrNull();

    if (existing != null) {
      await store
          .into(store.highlights)
          .insert(
            existing.copyWith(
              deleted: true,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
            mode: InsertMode.replace,
          );
    }
  }
}

// NOTES
final chapterNotesFamilyProvider = StreamProvider.family<List<Note>,
    ({String bookName, int chapter})>((ref, args) {
  final store = ref.watch(userStoreProvider);

  return (store.select(store.notes)..where(
        (n) =>
            (n.bookName.equals(args.bookName)) &
            (n.chapter.equals(args.chapter)) &
            (n.deleted.equals(false)),
      ))
      .watch();
});

/// Notes for the currently-selected chapter. Delegates to
/// [chapterNotesFamilyProvider] so each reader swipe page loads its own chapter.
final chapterNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);
  return ref.watch(
    chapterNotesFamilyProvider((bookName: bookName, chapter: chapter)),
  );
});

final chapterVersesWithNotesFamilyProvider =
    Provider.family<AsyncValue<Set<int>>, ({String bookName, int chapter})>(
        (ref, args) {
  final notesAsync = ref.watch(chapterNotesFamilyProvider(args));
  return notesAsync.whenData((notes) {
    final set = <int>{};
    for (final n in notes) {
      if (n.verse != null) set.add(n.verse!);
      if (n.selectedVerses != null) {
        final verses = n.selectedVerses!
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .whereType<int>();
        set.addAll(verses);
      }
    }
    return set;
  });
});

final chapterVersesWithNotesProvider = Provider<AsyncValue<Set<int>>>((ref) {
  final notesAsync = ref.watch(chapterNotesProvider);
  return notesAsync.whenData((notes) {
    final set = <int>{};
    for (final n in notes) {
      if (n.verse != null) set.add(n.verse!);
      if (n.selectedVerses != null) {
        final verses = n.selectedVerses!.split(',').map((e) => int.tryParse(e.trim())).whereType<int>();
        set.addAll(verses);
      }
    }
    return set;
  });
});

final noteActionProvider = Provider((ref) => NoteAction(ref));

class NoteAction {
  final Ref ref;
  NoteAction(this.ref);

  Future<void> saveNote(Set<int> verses, String content) async {
    final store = ref.read(userStoreProvider);
    final bookName = ref.read(selectedBookNameProvider);
    final chapter = ref.read(selectedChapterProvider);
    final deviceId = await ref.read(deviceIdProvider.future);

    String? versesString;
    int? primaryVerse;
    if (verses.isNotEmpty) {
      final sortedVerses = verses.toList()..sort();
      versesString = sortedVerses.join(', ');
      primaryVerse = sortedVerses.first;
    }

    // Simplification: match exactly on the selected verses string
    final query = store.select(store.notes)
      ..where(
        (n) =>
            (n.bookName.equals(bookName)) &
            (n.chapter.equals(chapter)) &
            (n.deleted.equals(false)),
      );

    if (verses.isNotEmpty) {
      if (verses.length == 1) {
        query.where((n) => n.selectedVerses.equals(versesString!) | (n.selectedVerses.isNull() & n.verse.equals(primaryVerse!)));
      } else {
        query.where((n) => n.selectedVerses.equals(versesString!));
      }
    } else {
      query.where((n) => n.verse.isNull() & n.selectedVerses.isNull());
    }

    final existing = await query.getSingleOrNull();

    if (existing != null) {
      await store
          .into(store.notes)
          .insert(
            existing.copyWith(
              content: content,
              selectedVerses: Value(versesString),
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
            mode: InsertMode.replace,
          );
    } else {
      final newNote = Note(
        id: const Uuid().v4(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: deviceId,
        deleted: false,
        bookName: bookName,
        chapter: chapter,
        verse: primaryVerse,
        selectedVerses: versesString,
        content: content,
      );
      await store.into(store.notes).insert(newNote);
    }
    ref.read(achievementServiceProvider).evaluateAchievements();
  }

  Future<void> deleteNote(String id) async {
    final store = ref.read(userStoreProvider);
    final existing = await (store.select(
      store.notes,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store
          .into(store.notes)
          .insert(
            existing.copyWith(
              deleted: true,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
            mode: InsertMode.replace,
          );
      await ref.read(tagControllerProvider).removeAllTagsFromEntity(id);
    }
  }
}

// BOOKMARKS
final chapterBookmarksProvider = StreamProvider<List<Bookmark>>((ref) {
  final store = ref.watch(userStoreProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);

  return (store.select(store.bookmarks)..where(
        (b) =>
            (b.bookName.equals(bookName)) &
            (b.chapter.equals(chapter)) &
            (b.deleted.equals(false)),
      ))
      .watch();
});

final bookmarkActionProvider = Provider<BookmarkAction>((ref) {
  return BookmarkAction(ref);
});

class BookmarkAction {
  final Ref ref;
  BookmarkAction(this.ref);

  Future<void> saveBookmark(int verse, String label) async {
    final store = ref.read(userStoreProvider);
    final bookName = ref.read(selectedBookNameProvider);
    final chapter = ref.read(selectedChapterProvider);
    final deviceId = await ref.read(deviceIdProvider.future);

    final newBookmark = Bookmark(
      id: const Uuid().v4(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      deviceId: deviceId,
      deleted: false,
      bookName: bookName,
      chapter: chapter,
      verse: verse,
      label: label,
    );
    await store.into(store.bookmarks).insert(newBookmark);
  }

  Future<void> deleteBookmark(String id) async {
    final store = ref.read(userStoreProvider);
    final existing = await (store.select(
      store.bookmarks,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store
          .into(store.bookmarks)
          .insert(
            existing.copyWith(
              deleted: true,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
            mode: InsertMode.replace,
          );
    }
  }
}

// NAVIGATION HISTORY
final navigationHistoryProvider = StreamProvider<List<NavigationHistory>>((
  ref,
) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.navigationHistories)
        ..where((h) => h.deleted.equals(false))
        ..orderBy([(h) => OrderingTerm.desc(h.updatedAt)])
        ..limit(25))
      .watch();
});
