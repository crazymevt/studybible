import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../data/user_store.dart';
import '../data/fts_text.dart';
import 'tag_providers.dart';
import 'user_providers.dart';
import 'sync_service.dart'; // for deviceIdProvider
import 'achievement_service.dart';
import 'revision_common.dart';

final allSermonsProvider = StreamProvider<List<Sermon>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.sermons)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)]))
      .watch();
});

/// Tags for every sermon at once, as `sermonId -> tags` (each list sorted by
/// name). The sermons panel uses this to show tag chips per row and to filter
/// the list by tag without opening an N-per-row subscription via
/// [tagsForEntityProvider].
final sermonTagsProvider = StreamProvider<Map<String, List<TagData>>>((ref) {
  final store = ref.watch(userStoreProvider);
  final query = store.select(store.entityTags).join([
    drift.innerJoin(
      store.tags,
      store.tags.id.equalsExp(store.entityTags.tagId),
    ),
  ])
    ..where(store.entityTags.entityType.equals('sermon'))
    ..where(store.entityTags.deleted.equals(false))
    ..where(store.tags.deleted.equals(false));

  return query.watch().map((rows) {
    final map = <String, List<TagData>>{};
    for (final row in rows) {
      final et = row.readTable(store.entityTags);
      final t = row.readTable(store.tags);
      (map[et.entityId] ??= []).add(
        TagData(id: t.id, name: t.name, colorHex: t.colorHex),
      );
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return map;
  });
});

/// Watches a single sermon row (including soft-deletes). The editor uses this
/// to notice when a remote sync overwrites the sermon while it's open.
final sermonByIdProvider =
    StreamProvider.family<Sermon?, String>((ref, id) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.sermons)..where((t) => t.id.equals(id)))
      .watchSingleOrNull();
});

/// Live, newest-first list of a sermon's saved revisions.
final sermonRevisionsProvider =
    StreamProvider.family<List<SermonRevision>, String>((ref, sermonId) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.sermonRevisions)
        ..where((t) => t.sermonId.equals(sermonId) & t.deleted.equals(false))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
      .watch();
});

class SelectedSermonIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) {
    state = id;
  }
}

final selectedSermonIdProvider = NotifierProvider<SelectedSermonIdNotifier, String?>(
  () => SelectedSermonIdNotifier(),
);

class SermonActionNotifier {
  final Ref _ref;
  final UserStore _store;

  SermonActionNotifier(this._ref, this._store);

  Future<Sermon> createSermon(String title, {String? series, String? content}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deviceId = await _ref.read(deviceIdProvider.future);
    final effectiveContent = content ?? '[{"insert":"\\n"}]';
    final sermon = SermonsCompanion.insert(
      id: const Uuid().v4(),
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      title: title,
      series: drift.Value(series),
      content: effectiveContent,
      contentPlain: drift.Value(deltaToPlainText(effectiveContent)),
    );
    await _store.into(_store.sermons).insert(sermon);
    _ref.read(achievementServiceProvider).evaluateAchievements();
    return (await (_store.select(_store.sermons)..where((t) => t.id.equals(sermon.id.value))).getSingle());
  }

  /// Writes the supplied fields and returns the `updatedAt` timestamp stamped on
  /// the row. The editor tracks this value so it can tell its own saves apart
  /// from a remote edit that landed underneath an open document.
  Future<int> updateSermon(String id, {String? title, String? series, String? content}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.sermons)..where((t) => t.id.equals(id))).write(
      SermonsCompanion(
        updatedAt: drift.Value(now),
        title: title != null ? drift.Value(title) : const drift.Value.absent(),
        series: series != null ? drift.Value(series) : const drift.Value.absent(),
        content: content != null ? drift.Value(content) : const drift.Value.absent(),
        contentPlain: content != null
            ? drift.Value(deltaToPlainText(content))
            : const drift.Value.absent(),
      ),
    );
    return now;
  }

  Future<void> deleteSermon(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.sermons)..where((t) => t.id.equals(id))).write(
      SermonsCompanion(
        deleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );
    await _ref.read(tagControllerProvider).removeAllTagsFromEntity(id);
  }
}

final sermonActionProvider = Provider<SermonActionNotifier>((ref) {
  final store = ref.watch(userStoreProvider);
  return SermonActionNotifier(ref, store);
});

class SermonRevisionActionNotifier {
  final Ref _ref;
  final UserStore _store;

  SermonRevisionActionNotifier(this._ref, this._store);

  /// Captures [content] (plus title/series) as a revision of [sermonId].
  /// Automatic kinds are pruned to [kMaxAutoRevisions] per sermon afterward;
  /// manual revisions are kept indefinitely.
  Future<void> saveRevision({
    required String sermonId,
    required String title,
    String? series,
    required String content,
    String? label,
    String kind = RevisionKind.manual,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deviceId = await _ref.read(deviceIdProvider.future);
    // For automatic snapshots (conflict / restore), skip if this exact content
    // is already preserved in a live revision of this sermon. The sync-side
    // failsafe and the editor's conflict flow can both snapshot the same losing
    // content, and re-snapshotting it only ever produces a redundant entry —
    // never the sole copy — so this can't lose data. We match against
    // non-deleted revisions only, so content that survives solely in a
    // tombstoned revision is still re-captured. Manual snapshots are always
    // kept (the user asked for one explicitly).
    if (kind != RevisionKind.manual) {
      final existing = await (_store.select(_store.sermonRevisions)
            ..where((t) =>
                t.sermonId.equals(sermonId) &
                t.deleted.equals(false) &
                t.content.equals(content)))
          .get();
      if (existing.isNotEmpty) return;
    }
    await _store.into(_store.sermonRevisions).insert(
          SermonRevisionsCompanion.insert(
            id: const Uuid().v4(),
            updatedAt: now,
            deviceId: deviceId,
            createdAt: now,
            sermonId: sermonId,
            title: title,
            series: drift.Value(series),
            content: content,
            label: drift.Value(label),
            kind: kind,
          ),
        );
    if (kind != RevisionKind.manual) {
      await _pruneAutoRevisions(sermonId);
    }
  }

  /// Restores [revisionId] into its sermon. The sermon's current content is
  /// first snapshotted as a [RevisionKind.restore] revision so the restore is
  /// itself reversible.
  Future<void> restoreRevision(String revisionId) async {
    final revision = await (_store.select(_store.sermonRevisions)
          ..where((t) => t.id.equals(revisionId)))
        .getSingleOrNull();
    if (revision == null) return;
    final sermon = await (_store.select(_store.sermons)
          ..where((t) => t.id.equals(revision.sermonId)))
        .getSingleOrNull();
    if (sermon == null) return;

    await saveRevision(
      sermonId: sermon.id,
      title: sermon.title,
      series: sermon.series,
      content: sermon.content,
      kind: RevisionKind.restore,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.sermons)..where((t) => t.id.equals(sermon.id)))
        .write(
      SermonsCompanion(
        updatedAt: drift.Value(now),
        title: drift.Value(revision.title),
        // Set series explicitly (not absent) so a restore faithfully clears it
        // when the snapshot had none.
        series: drift.Value(revision.series),
        content: drift.Value(revision.content),
        contentPlain: drift.Value(deltaToPlainText(revision.content)),
      ),
    );
  }

  Future<void> deleteRevision(String revisionId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.sermonRevisions)
          ..where((t) => t.id.equals(revisionId)))
        .write(
      SermonRevisionsCompanion(
        deleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );
  }

  /// Soft-deletes automatic revisions of [sermonId] beyond the most recent
  /// [kMaxAutoRevisions]. Manual revisions are excluded from the count and
  /// never pruned.
  Future<void> _pruneAutoRevisions(String sermonId) async {
    final auto = await (_store.select(_store.sermonRevisions)
          ..where((t) =>
              t.sermonId.equals(sermonId) &
              t.deleted.equals(false) &
              t.kind.equals(RevisionKind.manual).not())
          ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
        .get();
    if (auto.length <= kMaxAutoRevisions) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final stale in auto.skip(kMaxAutoRevisions)) {
      await (_store.update(_store.sermonRevisions)
            ..where((t) => t.id.equals(stale.id)))
          .write(
        SermonRevisionsCompanion(
          deleted: const drift.Value(true),
          updatedAt: drift.Value(now),
        ),
      );
    }
  }
}

final sermonRevisionActionProvider =
    Provider<SermonRevisionActionNotifier>((ref) {
  final store = ref.watch(userStoreProvider);
  return SermonRevisionActionNotifier(ref, store);
});
