import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

class ArchiveExtractor {
  /// Extracts a .zip or .zip.bz2 file to the target directory.
  /// Returns a list of extracted file paths.
  static Future<List<File>> extractArchive(
    File archiveFile,
    Directory targetDir,
  ) async {
    final bytes = await archiveFile.readAsBytes();
    Archive? archive;

    try {
      // Try BZip2 first
      final bzip2Decoder = BZip2Decoder();
      final uncompressed = bzip2Decoder.decodeBytes(bytes);
      if (uncompressed.isEmpty && bytes.isNotEmpty) {
        throw Exception('Not a valid bz2 file');
      }
      // After bzip2, the inner file is usually a zip containing the sqlite file
      archive = ZipDecoder().decodeBytes(uncompressed);
    } catch (e) {
      // Fallback to standard Zip
      try {
        archive = ZipDecoder().decodeBytes(bytes);
      } catch (e2) {
        throw Exception(
          'Failed to decode archive: Not a valid zip or bz2 file. ($e2)',
        );
      }
    }

    final List<File> extractedFiles = [];
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File(p.join(targetDir.path, filename));
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data);
        extractedFiles.add(outFile);
      } else {
        await Directory(
          p.join(targetDir.path, filename),
        ).create(recursive: true);
      }
    }

    return extractedFiles;
  }
}
