import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content_store.dart';
import '../domain/harmony/gospel_harmony.dart';
import 'content_providers.dart';

/// Loads and parses the bundled harmony of the Gospels once per session. The
/// dataset is a small (~150 event) curated asset, so it lives in memory rather
/// than the content DB.
final gospelHarmonyProvider = FutureProvider<GospelHarmony>((ref) async {
  final raw = await rootBundle.loadString('assets/data/gospel_harmony.json');
  return GospelHarmony.fromJsonString(raw);
});

/// The harmony event open in the Harmony panel, or null for the event list.
class SelectedHarmonyEventNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void select(int? id) => state = id;
}

final selectedHarmonyEventProvider =
    NotifierProvider<SelectedHarmonyEventNotifier, int?>(
  () => SelectedHarmonyEventNotifier(),
);

/// Reverse lookup: the harmony events whose account in [book] touches
/// ([chapter], [verse]). Empty outside the four Gospels.
final harmonyEventsForVerseProvider = FutureProvider.family<List<HarmonyEvent>,
    ({String book, int chapter, int verse})>((ref, loc) async {
  final harmony = await ref.watch(gospelHarmonyProvider.future);
  return harmony.eventsFor(loc.book, loc.chapter, loc.verse);
});

/// One Gospel account of a harmony event, resolved to verse rows in the
/// primary active version. Missing books (e.g. a version without the NT)
/// resolve to an empty list.
final harmonyPassageProvider = FutureProvider.family<List<Verse>,
    ({int eventId, String book})>((ref, key) async {
  final harmony = await ref.watch(gospelHarmonyProvider.future);
  final refRange = harmony.eventById(key.eventId)?.refFor(key.book);
  if (refRange == null) return const [];

  final versionId = ref.watch(primaryVersionIdProvider);
  if (versionId == null) return const [];
  final book = await ref.watch(
    bookByNameProvider((versionId: versionId, name: key.book)).future,
  );
  if (book == null) return const [];

  final store = ref.watch(contentStoreProvider);
  final rows = await (store.select(store.verses)
        ..where(
          (v) =>
              v.bookId.equals(book.id) &
              v.chapter.isBetweenValues(
                refRange.startChapter,
                refRange.endChapter,
              ),
        )
        ..orderBy([
          (v) => OrderingTerm.asc(v.chapter),
          (v) => OrderingTerm.asc(v.verse),
        ]))
      .get();
  return [
    for (final v in rows)
      if (!(v.chapter == refRange.startChapter &&
              v.verse < refRange.startVerse) &&
          !(v.chapter == refRange.endChapter && v.verse > refRange.endVerse))
        v,
  ];
});
