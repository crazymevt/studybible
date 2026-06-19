import 'dart:io';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/content_tables.dart';

part 'content_store.g.dart';

@DriftDatabase(tables: [
  Versions,
  Books,
  Verses,
  CrossReferences,
  Commentaries,
  CommentaryEntries,
  Dictionaries,
  DictionaryEntries,
])
class ContentStore extends _$ContentStore {
  ContentStore([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'content.db'));
    
    // Always overwrite from assets during development
    if (await file.exists()) {
      await file.delete();
    }
    
    if (!await file.exists()) {
      try {
        final blob = await rootBundle.load('assets/content.db');
        final buffer = blob.buffer;
        await file.writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
      } catch (e) {
        // Fallback or empty DB
      }
    }

    return NativeDatabase.createInBackground(file);
  });
}
