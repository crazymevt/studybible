import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

/// Thrown when a downloaded "archive" isn't one — typically because the source
/// server returned an empty page or an HTML error instead of the module file
/// (e.g. a broken/removed download link on ph4.org). Kept distinct from a
/// genuine decode failure so the UI can show a meaningful message.
class ModuleUnavailableException implements Exception {
  final String message;
  ModuleUnavailableException(this.message);
  @override
  String toString() => message;
}

class ArchiveExtractor {
  /// Extracts a .zip or .zip.bz2 file to the target directory.
  /// Returns a list of extracted file paths.
  static Future<List<File>> extractArchive(
    File archiveFile,
    Directory targetDir,
  ) async {
    final bytes = await archiveFile.readAsBytes();

    // A valid module archive starts with the bzip2 ("BZh") or zip ("PK") magic
    // bytes. Anything else — an empty body, whitespace, or an HTML error page —
    // means the server didn't actually serve the module (the download link is
    // dead or the module was removed upstream). Surface that clearly instead of
    // letting the decoders fail with a cryptic "not a valid zip or bz2" error.
    final looksLikeBzip2 =
        bytes.length >= 3 && bytes[0] == 0x42 && bytes[1] == 0x5A && bytes[2] == 0x68; // "BZh"
    final looksLikeZip =
        bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B; // "PK"
    if (!looksLikeBzip2 && !looksLikeZip) {
      throw ModuleUnavailableException(
        'This module appears to be unavailable from the source — the server '
        'returned an empty or non-archive response instead of the module file. '
        'The download link may be broken or the module may have been removed.',
      );
    }

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
