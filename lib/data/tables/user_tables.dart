import 'package:drift/drift.dart';

@DataClassName('Highlight')
class Highlights extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get colorHex => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Note')
class Notes extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer().nullable()();
  TextColumn get selectedVerses => text().nullable()();
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Bookmark')
class Bookmarks extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get label => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single, device-local scratch pad — rough notes that deliberately never
/// sync (kept out of [SyncService]). Stored as one row keyed by a fixed id;
/// content is Quill Delta JSON, matching journals/sermons so the pad can be
/// promoted into a sermon verbatim. No deviceId/deleted columns: it is local
/// state, not a sync entity.
@DataClassName('Scratch')
class Scratches extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()(); // Quill Delta JSON
  IntColumn get updatedAt => integer()(); // epoch ms

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Journal')
class Journals extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get title => text()();
  TextColumn get content =>
      text()(); // Quill Delta JSON (legacy rows: plain/markdown)
  // Plain-text projection of [content], derived on save, used only for the
  // full-text search index so the FTS vocab isn't polluted with Delta JSON.
  // Nullable so legacy rows migrate in cleanly (backfilled on upgrade).
  TextColumn get contentPlain => text().nullable()();
  TextColumn get tags => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A point-in-time snapshot of a [Journals] row. Like [SermonRevisions], a
/// revision's content is never edited after creation — only created or
/// tombstoned — so Last-Writer-Wins needs no special handling for them.
@DataClassName('JournalRevision')
class JournalRevisions extends Table {
  TextColumn get id => text()(); // UUID of the revision
  IntColumn get updatedAt => integer()(); // == createdAt; for the sync contract
  TextColumn get deviceId => text()(); // device that captured the snapshot
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get journalId => text()(); // the journal this snapshots
  IntColumn get createdAt => integer()(); // epoch ms the snapshot was taken
  TextColumn get title => text()(); // snapshot of the journal title
  TextColumn get content => text()(); // snapshot of the (markdown) content
  TextColumn get tags => text().nullable()(); // snapshot of the tags string
  TextColumn get label => text().nullable()(); // optional user-supplied label
  // 'manual', 'conflict', or 'restore' — see RevisionKind. Manual revisions are
  // kept forever; the automatic kinds are capped per journal.
  TextColumn get kind => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Sermon')
class Sermons extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get title => text()();
  TextColumn get series => text().nullable()();
  TextColumn get content => text()(); // Stores delta JSON string
  // Plain-text projection of [content], derived on save, used only for the
  // full-text search index so the FTS vocab isn't polluted with Delta JSON.
  TextColumn get contentPlain => text().nullable()();
  // Whether the sermon is pinned to the top of the list. Synced like the other
  // fields (Last-Writer-Wins), so a pin travels with the sermon across devices.
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A point-in-time snapshot of a [Sermons] row. A revision's content is never
/// edited after creation — it is only ever created or tombstoned (a delete
/// bumps [updatedAt] so the tombstone wins) — so Last-Writer-Wins needs no
/// special handling for them.
@DataClassName('SermonRevision')
class SermonRevisions extends Table {
  TextColumn get id => text()(); // UUID of the revision
  IntColumn get updatedAt => integer()(); // == createdAt; for the sync contract
  TextColumn get deviceId => text()(); // device that captured the snapshot
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get sermonId => text()(); // the sermon this snapshots
  IntColumn get createdAt => integer()(); // epoch ms the snapshot was taken
  TextColumn get title => text()(); // snapshot of the sermon title
  TextColumn get series => text().nullable()();
  TextColumn get content => text()(); // snapshot of the Delta JSON content
  TextColumn get label => text().nullable()(); // optional user-supplied label
  // 'manual' (user saved), 'conflict' (a remote edit overwrote local content),
  // or 'restore' (auto-snapshot of the pre-restore state). Manual revisions are
  // kept forever; the automatic kinds are capped per sermon.
  TextColumn get kind => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Prayer')
class Prayers extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get name => text()();
  TextColumn get description => text()();
  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get answeredAt =>
      integer().nullable()(); // epoch ms, null if not answered

  @override
  Set<Column> get primaryKey => {id};
}

/// A to-do / action item shown alongside journals and prayers. Mirrors
/// [Prayers] (createdAt + a nullable completion timestamp) but adds an optional
/// [dueAt] so the app can alert the user as it comes due.
@DataClassName('ActionItem')
class ActionItems extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get title => text()(); // the action
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get dueAt =>
      integer().nullable()(); // epoch ms, optional due date/time
  IntColumn get completedAt =>
      integer().nullable()(); // epoch ms, null while not completed

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReadingProgress')
class ReadingProgresses extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get readAt => integer()(); // epoch ms
  IntColumn get iteration => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TimeTracker')
class TimeTrackers extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  IntColumn get startTime => integer()(); // epoch ms
  IntColumn get endTime => integer()(); // epoch ms
  IntColumn get durationMs => integer()();
  TextColumn get activityType => text()(); // e.g. "reading"

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Achievement')
class Achievements extends Table {
  TextColumn get id => text()(); // The badge identifier
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  IntColumn get unlockedAt => integer()(); // epoch ms

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NavigationHistory')
class NavigationHistories extends Table {
  TextColumn get id => text()(); // UUID
  IntColumn get updatedAt => integer()(); // epoch ms
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer().nullable()();
  TextColumn get verseText => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReadingPlan')
class ReadingPlans extends Table {
  TextColumn get id => text()(); // UUID
  IntColumn get updatedAt => integer()(); // epoch ms
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get startDate => integer()(); // epoch ms
  IntColumn get targetEndDate => integer().nullable()(); // epoch ms

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReadingPlanDay')
class ReadingPlanDays extends Table {
  TextColumn get id => text()(); // UUID
  IntColumn get updatedAt => integer()(); // epoch ms
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get planId => text()();
  IntColumn get dayNumber => integer()();
  IntColumn get date =>
      integer().nullable()(); // epoch ms, for absolute tracking
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReadingPlanItem')
class ReadingPlanItems extends Table {
  TextColumn get id => text()(); // UUID
  IntColumn get updatedAt => integer()(); // epoch ms
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get dayId => text()();
  TextColumn get bookName => text()();
  IntColumn get startChapter => integer()();
  IntColumn get endChapter => integer()();
  IntColumn get startVerse => integer().nullable()();
  IntColumn get endVerse => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Tag')
class Tags extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get name => text()();
  TextColumn get colorHex => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EntityTag')
class EntityTags extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get tagId => text()();
  TextColumn get entityId => text()();
  TextColumn get entityType => text()();

  @override
  Set<Column> get primaryKey => {id};
}
