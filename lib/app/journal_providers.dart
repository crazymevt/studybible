import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../data/user_store.dart';
import 'user_providers.dart';
import 'sync_service.dart';
import 'achievement_service.dart';
import 'tag_providers.dart';
import 'revision_common.dart';

// JOURNALS
final journalsProvider = StreamProvider<List<Journal>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.journals)
        ..where((j) => j.deleted.equals(false))
        ..orderBy([
          (j) => OrderingTerm(expression: j.updatedAt, mode: OrderingMode.desc),
        ]))
      .watch();
});

/// Watches a single journal row. The editor uses this to notice when a sync
/// overwrites the journal while it's open.
final journalByIdProvider = StreamProvider.family<Journal?, String>((ref, id) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.journals)..where((j) => j.id.equals(id)))
      .watchSingleOrNull();
});

/// Live, newest-first list of a journal's saved revisions.
final journalRevisionsProvider =
    StreamProvider.family<List<JournalRevision>, String>((ref, journalId) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.journalRevisions)
        ..where((t) => t.journalId.equals(journalId) & t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
});

final journalRevisionActionProvider =
    Provider((ref) => JournalRevisionAction(ref));

class JournalRevisionAction {
  final Ref ref;
  JournalRevisionAction(this.ref);

  /// Captures [content] (plus title/tags) as a revision of [journalId].
  /// Automatic kinds are pruned to [kMaxAutoRevisions]; manual ones are kept.
  Future<void> saveRevision({
    required String journalId,
    required String title,
    required String content,
    String? tags,
    String? label,
    String kind = RevisionKind.manual,
  }) async {
    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;
    await store.into(store.journalRevisions).insert(
          JournalRevisionsCompanion.insert(
            id: const Uuid().v4(),
            updatedAt: now,
            deviceId: deviceId,
            createdAt: now,
            journalId: journalId,
            title: title,
            content: content,
            tags: Value(tags),
            label: Value(label),
            kind: kind,
          ),
        );
    if (kind != RevisionKind.manual) await _pruneAuto(journalId);
  }

  /// Restores [revisionId] into its journal, snapshotting the current content
  /// first so the restore is reversible. The journal's [Journals.updatedAt]
  /// (its calendar date) is preserved — restoring does not re-date the entry.
  Future<void> restoreRevision(String revisionId) async {
    final store = ref.read(userStoreProvider);
    final revision = await (store.select(store.journalRevisions)
          ..where((t) => t.id.equals(revisionId)))
        .getSingleOrNull();
    if (revision == null) return;
    final journal = await (store.select(store.journals)
          ..where((j) => j.id.equals(revision.journalId)))
        .getSingleOrNull();
    if (journal == null) return;

    await saveRevision(
      journalId: journal.id,
      title: journal.title,
      content: journal.content,
      tags: journal.tags,
      kind: RevisionKind.restore,
    );

    await store.into(store.journals).insert(
          journal.copyWith(
            title: revision.title,
            content: revision.content,
            tags: Value(revision.tags),
            // Keep the entry's date; only its content is being rolled back.
          ),
          mode: InsertMode.replace,
        );
  }

  Future<void> deleteRevision(String revisionId) async {
    final store = ref.read(userStoreProvider);
    await (store.update(store.journalRevisions)
          ..where((t) => t.id.equals(revisionId)))
        .write(
      JournalRevisionsCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> _pruneAuto(String journalId) async {
    final store = ref.read(userStoreProvider);
    final auto = await (store.select(store.journalRevisions)
          ..where((t) =>
              t.journalId.equals(journalId) &
              t.deleted.equals(false) &
              t.kind.equals(RevisionKind.manual).not())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    if (auto.length <= kMaxAutoRevisions) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final stale in auto.skip(kMaxAutoRevisions)) {
      await (store.update(store.journalRevisions)
            ..where((t) => t.id.equals(stale.id)))
          .write(
        JournalRevisionsCompanion(
          deleted: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
  }
}

final journalActionProvider = Provider((ref) => JournalAction(ref));

class JournalAction {
  final Ref ref;
  JournalAction(this.ref);

  Future<String> saveJournal(
    String? id,
    String title,
    String content, {
    String? tags,
    DateTime? dateOverride,
  }) async {
    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);

    final journalId = id ?? const Uuid().v4();
    final existing = id != null
        ? await (store.select(
            store.journals,
          )..where((j) => j.id.equals(id))).getSingleOrNull()
        : null;

    final updateTime =
        dateOverride?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;

    if (existing != null) {
      await store
          .into(store.journals)
          .insert(
            existing.copyWith(
              title: title,
              content: content,
              tags: Value(tags),
              // We don't overwrite updatedAt with a backdate if it's already an existing entry, unless we specifically want to.
              // Since the user is editing it *now*, we might want to keep its original date if it's backdated,
              // or update to now. Let's keep it simple: use the override if provided.
              updatedAt: updateTime,
            ),
            mode: InsertMode.replace,
          );
    } else {
      final newJournal = Journal(
        id: journalId,
        updatedAt: updateTime,
        deviceId: deviceId,
        deleted: false,
        title: title,
        content: content,
        tags: tags,
      );
      await store.into(store.journals).insert(newJournal);
    }
    return journalId;
  }

  Future<void> deleteJournal(String id) async {
    final store = ref.read(userStoreProvider);
    final existing = await (store.select(
      store.journals,
    )..where((j) => j.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store
          .into(store.journals)
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

// PRAYERS
final prayersProvider = StreamProvider<List<Prayer>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.prayers)
        ..where((p) => p.deleted.equals(false))
        ..orderBy([
          (p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.desc),
        ]))
      .watch();
});

final prayerActionProvider = Provider((ref) => PrayerAction(ref));

class PrayerAction {
  final Ref ref;
  PrayerAction(this.ref);

  Future<String> savePrayer(String? id, String name, String description) async {
    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;

    final prayerId = id ?? const Uuid().v4();
    final existing = id != null
        ? await (store.select(
            store.prayers,
          )..where((p) => p.id.equals(id))).getSingleOrNull()
        : null;

    if (existing != null) {
      await store
          .into(store.prayers)
          .insert(
            existing.copyWith(
              name: name,
              description: description,
              updatedAt: now,
            ),
            mode: InsertMode.replace,
          );
    } else {
      final newPrayer = Prayer(
        id: prayerId,
        updatedAt: now,
        deviceId: deviceId,
        deleted: false,
        name: name,
        description: description,
        createdAt: now,
        answeredAt: null,
      );
      await store.into(store.prayers).insert(newPrayer);
    }
    ref.read(achievementServiceProvider).evaluateAchievements();
    return prayerId;
  }

  Future<void> toggleAnswered(String id, bool answered) async {
    final store = ref.read(userStoreProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await (store.select(
      store.prayers,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store
          .into(store.prayers)
          .insert(
            existing.copyWith(
              answeredAt: Value(answered ? now : null),
              updatedAt: now,
            ),
            mode: InsertMode.replace,
          );
    }
    ref.read(achievementServiceProvider).evaluateAchievements();
  }

  Future<void> deletePrayer(String id) async {
    final store = ref.read(userStoreProvider);
    final existing = await (store.select(
      store.prayers,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store
          .into(store.prayers)
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
