import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../data/user_store.dart';
import 'reader_state.dart';

final userStoreProvider = Provider<UserStore>((ref) {
  return UserStore();
});

final chapterHighlightsProvider = StreamProvider<Set<int>>((ref) {
  final store = ref.watch(userStoreProvider);
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);

  return (store.select(store.highlights)
        ..where((h) => h.bookName.equals(bookName) & h.chapter.equals(chapter) & h.deleted.equals(false)))
      .watch()
      .map((highlights) => highlights.map((h) => h.verse).toSet());
});

final highlightActionProvider = Provider((ref) {
  return HighlightAction(ref);
});

class HighlightAction {
  final Ref ref;
  HighlightAction(this.ref);

  Future<void> toggleHighlight(int verse) async {
    final store = ref.read(userStoreProvider);
    final bookName = ref.read(selectedBookNameProvider);
    final chapter = ref.read(selectedChapterProvider);

    final existing = await (store.select(store.highlights)
          ..where((h) => h.bookName.equals(bookName) & h.chapter.equals(chapter) & h.verse.equals(verse) & h.deleted.equals(false)))
        .getSingleOrNull();

    if (existing != null) {
      await store.into(store.highlights).insert(
        existing.copyWith(
          deleted: true,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
        mode: InsertMode.replace,
      );
    } else {
      final newHighlight = Highlight(
        id: const Uuid().v4(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'local-device',
        deleted: false,
        bookName: bookName,
        chapter: chapter,
        verse: verse,
        colorHex: '#FFFF00',
      );
      await store.into(store.highlights).insert(newHighlight);
    }
  }
}
