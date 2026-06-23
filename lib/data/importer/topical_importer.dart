import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../content_store.dart';

/// Loads the bundled Nave's Topical Bible asset into the content store on first
/// use. The data is public domain (Nave's) via the CC-BY-4.0
/// BradyStephenson/bible-data project, converted to JSON by
/// `tool/build_naves_topical.dart`.
class TopicalImporter {
  TopicalImporter(this.store);

  final ContentStore store;

  static const String assetPath = 'assets/data/naves_topical.json';

  Future<int> _topicCount() async {
    final countExp = store.topics.id.count();
    final query = store.selectOnly(store.topics)..addColumns([countExp]);
    return await query.map((row) => row.read(countExp)).getSingle() ?? 0;
  }

  Future<int> _indexedTopicCount() async {
    final row = await store
        .customSelect("SELECT COUNT(*) AS c FROM content_search WHERE type = 'topic'")
        .getSingle();
    return row.read<int>('c');
  }

  /// Inserts topic names into the global FTS index if absent. Self-heals DBs
  /// that loaded topics before search indexing existed.
  Future<void> _ensureIndexed() async {
    if (await _indexedTopicCount() == 0 && await _topicCount() > 0) {
      await store.customStatement(
        "INSERT INTO content_search(type, reference_id, text_content) "
        "SELECT 'topic', id, name FROM topics",
      );
    }
  }

  /// Idempotent: loads the topical index once and ensures it is searchable.
  Future<void> ensureLoaded() async {
    if (await _topicCount() > 0) {
      await _ensureIndexed();
      return;
    }

    final raw = await rootBundle.loadString(assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final books = (data['books'] as List).cast<String>();
    final topics = data['topics'] as List;

    // Assign explicit IDs so entries/refs can reference their parents without a
    // round-trip per row — the whole import is a single batched transaction.
    final topicRows = <TopicsCompanion>[];
    final entryRows = <TopicEntriesCompanion>[];
    final refRows = <TopicReferencesCompanion>[];
    var topicId = 0, entryId = 0, refId = 0;

    for (final t in topics) {
      topicId++;
      topicRows.add(TopicsCompanion(
        id: Value(topicId),
        name: Value(t['t'] as String),
        section: Value((t['s'] as String?) ?? ''),
      ));
      var ordinal = 0;
      for (final e in (t['e'] as List)) {
        entryId++;
        ordinal++;
        final see = (e['see'] as List).cast<String>();
        entryRows.add(TopicEntriesCompanion(
          id: Value(entryId),
          topicId: Value(topicId),
          ordinal: Value(ordinal),
          description: Value((e['d'] as String?) ?? ''),
          seeAlso: Value(see.isEmpty ? null : see.join('\n')),
        ));
        for (final r in (e['r'] as List)) {
          refId++;
          final ref = (r as List);
          refRows.add(TopicReferencesCompanion(
            id: Value(refId),
            topicId: Value(topicId),
            entryId: Value(entryId),
            bookName: Value(books[ref[0] as int]),
            chapter: Value(ref[1] as int),
            verse: Value(ref[2] as int?),
            verseEnd: Value(ref[3] as int?),
          ));
        }
      }
    }

    await store.batch((b) {
      b.insertAll(store.topics, topicRows);
      b.insertAll(store.topicEntries, entryRows);
      b.insertAll(store.topicReferences, refRows);
    });

    // Index topic names into the global full-text search.
    await store.customStatement(
      "INSERT INTO content_search(type, reference_id, text_content) "
      "SELECT 'topic', id, name FROM topics",
    );
  }
}
