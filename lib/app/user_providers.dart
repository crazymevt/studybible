import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../data/user_store.dart';
import 'reader_state.dart';
import 'sync_service.dart';

final userStoreProvider = Provider<UserStore>((ref) {
  return UserStore();
});

// A stream provider that emits the Map of highlighted verses for the current book/chapter.
final chapterHighlightsProvider = StreamProvider<Map<int, String>>((ref) {
  final store = ref.watch(userStoreProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);

  return (store.select(store.highlights)
        ..where((h) => (h.bookName.equals(bookName)) & (h.chapter.equals(chapter)) & (h.deleted.equals(false))))
      .watch()
      .map((highlights) => { for (var h in highlights) h.verse: h.colorHex });
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

    final existing = await (store.select(store.highlights)
          ..where((h) => (h.bookName.equals(bookName)) & (h.chapter.equals(chapter)) & (h.verse.equals(verse)) & (h.deleted.equals(false))))
        .getSingleOrNull();

    if (existing != null) {
      if (existing.colorHex == colorHex) {
        // Toggle off if same color
        await store.into(store.highlights).insert(
          existing.copyWith(deleted: true, updatedAt: DateTime.now().millisecondsSinceEpoch),
          mode: InsertMode.replace,
        );
      } else {
        // Change color
        await store.into(store.highlights).insert(
          existing.copyWith(colorHex: colorHex, updatedAt: DateTime.now().millisecondsSinceEpoch),
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
  }
}

// NOTES
final chapterNotesProvider = StreamProvider<List<Note>>((ref) {
  final store = ref.watch(userStoreProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);

  return (store.select(store.notes)
        ..where((n) => (n.bookName.equals(bookName)) & (n.chapter.equals(chapter)) & (n.deleted.equals(false))))
      .watch();
});

final noteActionProvider = Provider((ref) => NoteAction(ref));

class NoteAction {
  final Ref ref;
  NoteAction(this.ref);

  Future<void> saveNote(int? verse, String content) async {
    final store = ref.read(userStoreProvider);
    final bookName = ref.read(selectedBookNameProvider);
    final chapter = ref.read(selectedChapterProvider);
    final deviceId = await ref.read(deviceIdProvider.future);

    // Simplification: one note per verse or one general chapter note
    final query = store.select(store.notes)
      ..where((n) => (n.bookName.equals(bookName)) & (n.chapter.equals(chapter)) & (n.deleted.equals(false)));
      
    if (verse != null) {
      query.where((n) => n.verse.equals(verse));
    } else {
      query.where((n) => n.verse.isNull());
    }

    final existing = await query.getSingleOrNull();

    if (existing != null) {
      await store.into(store.notes).insert(
        existing.copyWith(content: content, updatedAt: DateTime.now().millisecondsSinceEpoch),
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
        verse: verse,
        content: content,
      );
      await store.into(store.notes).insert(newNote);
    }
  }
  
  Future<void> deleteNote(String id) async {
    final store = ref.read(userStoreProvider);
    final existing = await (store.select(store.notes)..where((n) => n.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store.into(store.notes).insert(
        existing.copyWith(deleted: true, updatedAt: DateTime.now().millisecondsSinceEpoch),
        mode: InsertMode.replace,
      );
    }
  }
}

// BOOKMARKS
final chapterBookmarksProvider = StreamProvider<List<Bookmark>>((ref) {
  final store = ref.watch(userStoreProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);

  return (store.select(store.bookmarks)
        ..where((b) => (b.bookName.equals(bookName)) & (b.chapter.equals(chapter)) & (b.deleted.equals(false))))
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
    final existing = await (store.select(store.bookmarks)..where((b) => b.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store.into(store.bookmarks).insert(
        existing.copyWith(deleted: true, updatedAt: DateTime.now().millisecondsSinceEpoch),
        mode: InsertMode.replace,
      );
    }
  }
}
