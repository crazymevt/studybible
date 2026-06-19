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

@DataClassName('Prayer')
class Prayers extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get name => text()();
  TextColumn get description => text()();
  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get answeredAt => integer().nullable()(); // epoch ms, null if not answered

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
