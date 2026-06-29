import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/importer/archive_extractor.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('archive_extractor_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<File> writeFile(String name, List<int> bytes) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsBytes(bytes);
    return f;
  }

  group('extractArchive guards against non-archive responses', () {
    // ph4.org serves a ~2-byte blank page (or an HTML error) instead of the
    // module when a download link is dead. The extractor must report that as a
    // ModuleUnavailableException, not a cryptic decode failure.
    test('throws ModuleUnavailableException for an empty/blank response',
        () async {
      final file = await writeFile('blank.zip.bz2', '\r\n'.codeUnits);
      expect(
        () => ArchiveExtractor.extractArchive(file, Directory('${tmp.path}/o')),
        throwsA(isA<ModuleUnavailableException>()),
      );
    });

    test('throws ModuleUnavailableException for an HTML error page', () async {
      final file = await writeFile(
        'err.zip.bz2',
        '<html><body>Not found</body></html>'.codeUnits,
      );
      expect(
        () => ArchiveExtractor.extractArchive(file, Directory('${tmp.path}/o')),
        throwsA(isA<ModuleUnavailableException>()),
      );
    });

    test('extracts a real zip archive', () async {
      final archive = Archive()
        ..addFile(ArchiveFile('module.sqlite3', 3, [1, 2, 3]));
      final zipped = ZipEncoder().encode(archive)!;
      final file = await writeFile('real.zip', zipped);

      final out = Directory('${tmp.path}/out');
      final extracted =
          await ArchiveExtractor.extractArchive(file, out);

      expect(extracted, hasLength(1));
      expect(extracted.first.path, endsWith('module.sqlite3'));
    });
  });
}
