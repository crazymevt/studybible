import 'package:drift/drift.dart';

@DataClassName('Highlight')
class Highlights extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  // We use bookName instead of bookId for cross-version consistency
  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  
  TextColumn get colorHex => text()();

  @override
  Set<Column> get primaryKey => {id};
}
