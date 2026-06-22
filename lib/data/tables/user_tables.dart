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

@DataClassName('Journal')
class Journals extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get tags => text().nullable()();

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
