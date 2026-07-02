import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_store.dart';
import 'sermon_providers.dart';
import 'user_providers.dart';

/// The single scratch pad is stored as one row under this fixed id. The pad is
/// deliberately device-local — it is never added to [SyncService]'s record set.
const String kScratchPadId = 'scratch';

/// The scratch pad's stored content (Quill Delta JSON), or an empty string
/// before anything has been written. A single-row stream so the editor can
/// load it once and react if it's cleared.
final scratchContentProvider = StreamProvider<String>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.scratches)
        ..where((s) => s.id.equals(kScratchPadId)))
      .watchSingleOrNull()
      .map((row) => row?.content ?? '');
});

final scratchActionProvider = Provider<ScratchAction>((ref) => ScratchAction(ref));

class ScratchAction {
  final Ref ref;
  ScratchAction(this.ref);

  /// Upserts the single scratch row with [content] (Quill Delta JSON).
  Future<void> save(String content) async {
    final store = ref.read(userStoreProvider);
    await store
        .into(store.scratches)
        .insertOnConflictUpdate(
          ScratchesCompanion.insert(
            id: kScratchPadId,
            content: content,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  /// Empties the pad.
  Future<void> clear() => save('');

  /// Creates a full sermon from the pad's current [content] (verbatim, since
  /// both store Quill Delta) and returns it. The pad is left untouched — the
  /// caller decides whether to clear it.
  Future<Sermon> promoteToSermon(String title, String content) {
    return ref
        .read(sermonActionProvider)
        .createSermon(title, content: content);
  }
}
