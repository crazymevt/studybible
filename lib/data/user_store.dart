import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/user_tables.dart';

part 'user_store.g.dart';

@DriftDatabase(tables: [Highlights])
class UserStore extends _$UserStore {
  UserStore([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'user.db'));
    return NativeDatabase.createInBackground(file);
  });
}
