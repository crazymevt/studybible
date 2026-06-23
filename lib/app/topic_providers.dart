import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content_store.dart';
import '../data/importer/topical_importer.dart';
import 'content_providers.dart';

final topicalImporterProvider = Provider<TopicalImporter>(
  (ref) => TopicalImporter(ref.watch(contentStoreProvider)),
);

/// Loads the bundled Nave's topical index into the DB on first access, then
/// resolves. Watch this before querying topics so the UI can show progress.
final topicalIndexReadyProvider = FutureProvider<bool>((ref) async {
  await ref.watch(topicalImporterProvider).ensureLoaded();
  return true;
});

class TopicSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final topicSearchQueryProvider =
    NotifierProvider<TopicSearchQueryNotifier, String>(
  () => TopicSearchQueryNotifier(),
);

/// Topic name search. Prefix matches rank first, then any substring match.
final topicSearchResultsProvider = FutureProvider<List<Topic>>((ref) async {
  await ref.watch(topicalIndexReadyProvider.future);
  final store = ref.watch(contentStoreProvider);
  final query = ref.watch(topicSearchQueryProvider).trim();
  if (query.isEmpty) return [];

  final q = store.select(store.topics)
    ..where((t) => t.name.like('%${query.toUpperCase()}%'))
    ..orderBy([(t) => OrderingTerm.asc(t.name)])
    ..limit(200);
  final rows = await q.get();

  final upper = query.toUpperCase();
  rows.sort((a, b) {
    final ap = a.name.startsWith(upper) ? 0 : 1;
    final bp = b.name.startsWith(upper) ? 0 : 1;
    if (ap != bp) return ap - bp;
    return a.name.compareTo(b.name);
  });
  return rows;
});

class TopicEntryView {
  final TopicEntry entry;
  final List<TopicReference> refs;
  TopicEntryView(this.entry, this.refs);
}

class TopicDetail {
  final Topic topic;
  final List<TopicEntryView> entries;
  TopicDetail(this.topic, this.entries);
}

final topicDetailProvider =
    FutureProvider.family<TopicDetail?, int>((ref, topicId) async {
  final store = ref.watch(contentStoreProvider);
  final topic = await (store.select(store.topics)
        ..where((t) => t.id.equals(topicId)))
      .getSingleOrNull();
  if (topic == null) return null;

  final entries = await (store.select(store.topicEntries)
        ..where((e) => e.topicId.equals(topicId))
        ..orderBy([(e) => OrderingTerm.asc(e.ordinal)]))
      .get();
  final refs = await (store.select(store.topicReferences)
        ..where((r) => r.topicId.equals(topicId))
        ..orderBy([(r) => OrderingTerm.asc(r.id)]))
      .get();

  final byEntry = <int, List<TopicReference>>{};
  for (final r in refs) {
    byEntry.putIfAbsent(r.entryId, () => []).add(r);
  }
  return TopicDetail(
    topic,
    entries.map((e) => TopicEntryView(e, byEntry[e.id] ?? const [])).toList(),
  );
});

/// A topic that references a given verse (reverse lookup), with the subtopic
/// description that matched.
class TopicForVerse {
  final int topicId;
  final String topicName;
  final String description;
  TopicForVerse(this.topicId, this.topicName, this.description);
}

/// Reverse lookup: which topics reference (book, chapter, verse)? Matches whole
/// chapter refs, single verses, and verse ranges.
final topicsForVerseProvider = FutureProvider.family<List<TopicForVerse>,
    ({String book, int chapter, int verse})>((ref, loc) async {
  await ref.watch(topicalIndexReadyProvider.future);
  final store = ref.watch(contentStoreProvider);
  final rows = await store.customSelect(
    '''
    SELECT DISTINCT t.id AS id, t.name AS name, e.description AS description
    FROM topic_references r
    JOIN topics t ON t.id = r.topic_id
    JOIN topic_entries e ON e.id = r.entry_id
    WHERE r.book_name = ? AND r.chapter = ? AND (
      r.verse IS NULL
      OR (r.verse_end IS NULL AND r.verse = ?)
      OR (r.verse_end IS NOT NULL AND r.verse <= ? AND r.verse_end >= ?)
    )
    ORDER BY t.name
    ''',
    variables: [
      Variable.withString(loc.book),
      Variable.withInt(loc.chapter),
      Variable.withInt(loc.verse),
      Variable.withInt(loc.verse),
      Variable.withInt(loc.verse),
    ],
  ).get();
  return rows
      .map((r) => TopicForVerse(
            r.read<int>('id'),
            r.read<String>('name'),
            r.read<String>('description'),
          ))
      .toList();
});

/// Resolve a topic id by exact (case-insensitive) name — used to follow
/// "See also" cross-references straight to the target topic.
final topicIdByNameProvider =
    FutureProvider.family<int?, String>((ref, name) async {
  final store = ref.watch(contentStoreProvider);
  final row = await (store.select(store.topics)
        ..where((t) => t.name.equals(name.trim().toUpperCase()))
        ..limit(1))
      .getSingleOrNull();
  return row?.id;
});

/// The topic the user is currently viewing in the Topics panel.
class SelectedTopicNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void select(int? id) => state = id;
}

final selectedTopicProvider =
    NotifierProvider<SelectedTopicNotifier, int?>(() => SelectedTopicNotifier());
