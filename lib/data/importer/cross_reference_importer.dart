import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:study_bible/data/content_store.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

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
    // Use a unique temp name so an overlapping or previously-killed import can't
    // read/write the same file and corrupt it (seen as "database disk image is
    // malformed" when two copies raced on a fixed path).
    final tempFile = File(
      p.join(tempDir.path, 'cross_references_${const Uuid().v4()}.sqlite'),
    );

    // Copy from assets to temp file
    final byteData = await rootBundle.load('assets/cross_references.sqlite');
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());

    final db = sqlite.sqlite3.open(tempFile.path);
    final results = db.select('SELECT * FROM cross_references');

    await store.batch((batch) {
      // Clear first so the import is idempotent: the count check above is not
      // atomic, so two overlapping first-run imports could both pass it. The
      // batch runs in one transaction and writers are serialized, so whichever
      // runs second clears the other's rows and re-inserts — the table always
      // ends with exactly one copy instead of duplicates.
      batch.deleteAll(store.crossReferences);
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
