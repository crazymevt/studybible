import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:study_bible/data/content_store.dart';
import 'package:drift/drift.dart' as drift;

class CrossReferenceImporter {
  final ContentStore store;

  CrossReferenceImporter(this.store);

  Future<void> importIfEmpty() async {
    // Check if we already imported cross references
    final countRow = await store.customSelect('SELECT COUNT(*) as c FROM cross_references').getSingle();
    if (countRow.read<int>('c') > 0) {
      return; // Already populated
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/cross_references.sqlite');
    
    // Copy from assets to temp file
    final byteData = await rootBundle.load('assets/cross_references.sqlite');
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());

    final db = sqlite.sqlite3.open(tempFile.path);
    final results = db.select('SELECT * FROM cross_references');

    await store.batch((batch) {
      for (final row in results) {
        batch.insert(
          store.crossReferences,
          CrossReferencesCompanion.insert(
            sourceBookName: row['sourceBookName'] as String,
            sourceChapter: int.tryParse(row['sourceChapter'].toString()) ?? 0,
            sourceVerse: int.tryParse(row['sourceVerse'].toString()) ?? 0,
            targetBookName: row['targetBookName'] as String,
            targetChapter: int.tryParse(row['targetChapter'].toString()) ?? 0,
            targetVerse: int.tryParse(row['targetVerse'].toString()) ?? 0,
            votes: drift.Value(int.tryParse(row['votes']?.toString() ?? '')),
          ),
        );
      }
    });

    db.close();
    try {
      await tempFile.delete();
    } catch (_) {
      // Ignore if it couldn't be deleted
    }
  }
}
