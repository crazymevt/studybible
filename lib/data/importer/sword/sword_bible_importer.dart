import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../content_store.dart';
import '../../models/verse_segment.dart';
import 'gbf_fragment_parser.dart';
import 'osis_fragment_parser.dart';
import 'parsed_verse_entry.dart';
import 'sword_config.dart';
import 'sword_rawtext_reader.dart';
import 'sword_verse_reader.dart';
import 'sword_versification.dart';
import 'sword_ztext_reader.dart';
import 'thml_fragment_parser.dart';

/// Imports a SWORD Bible module (`zText`/`zText4` compressed, or
/// `RawText`/`RawText4` uncompressed) into the content store, mapping it onto
/// `versions`/`books`/`verses` exactly as the OSIS and MyBible importers do.
///
/// The walk is driven by the module's versification (see
/// `sword_versification.dart`): for every book/chapter/verse slot it computes
/// the index, reads the raw entry via a [SwordVerseReader], parses the markup,
/// and accumulates verse rows. Books with no present verses are skipped, so a
/// partial (e.g. NT-only) module yields only the books it actually contains.
///
/// Scope: `zText`/`RawText` Bibles with the `KJV` versification and
/// `OSIS`/plaintext source. Other drivers, versifications, source types, and
/// compression schemes throw a clear error rather than importing garbage.
class SwordBibleImporter {
  final ContentStore store;

  SwordBibleImporter(this.store);

  /// Import the module described by [config], reading data from the module's
  /// directory tree rooted at [moduleRoot] (the conf's `DataPath` is resolved
  /// against it). Throws if the testament data files are missing.
  Future<void> importFromDirectory(
    Directory moduleRoot,
    SwordConfig config,
  ) async {
    final rel = (config.dataPath ?? '').replaceFirst(RegExp(r'^\./'), '');
    final dataDir = Directory(p.normalize(p.join(moduleRoot.path, rel)));

    // Compressed (z*) and uncompressed (Raw*) Bibles share the same positional
    // verse index but a different on-disk layout, so pick the matching reader.
    final compressed = config.modDrv.isCompressed;
    Future<SwordVerseReader?> readerFor(String testament) => compressed
        ? SwordZTextReader.fromTestamentFiles(dataDir, testament, config)
        : SwordRawTextReader.fromTestamentFiles(dataDir, testament, config);

    final ot = await readerFor('ot');
    final nt = await readerFor('nt');
    if (ot == null && nt == null) {
      throw Exception(
        'No SWORD testament data files found under "${dataDir.path}".',
      );
    }
    await importBible(config, ot: ot, nt: nt);
  }

  /// Core import: walk the versification and write the module backed by the
  /// supplied testament [ot]/[nt] readers (either may be null). Separated from
  /// file resolution so it can be driven from in-memory readers in tests.
  Future<void> importBible(
    SwordConfig config, {
    SwordVerseReader? ot,
    SwordVerseReader? nt,
  }) async {
    if (!config.modDrv.isBible) {
      throw UnsupportedError(
        'SwordBibleImporter handles Bible modules (zText/RawText); '
        'got ModDrv "${config.value('ModDrv')}".',
      );
    }
    if (config.sourceType == SwordSourceType.tei) {
      throw UnsupportedError(
        'SWORD ${config.sourceType.name} source is not yet supported; '
        'OSIS, GBF, ThML, and plaintext modules can be imported.',
      );
    }
    final versification = swordVersificationByName(config.versification);
    if (versification == null) {
      throw UnsupportedError(
        'SWORD versification "${config.versification}" is not yet supported; '
        'only KJV is available.',
      );
    }

    final vid = config.name.toUpperCase();
    await store.deleteVersion(vid);
    await store.into(store.versions).insert(
          VersionsCompanion.insert(
            id: vid,
            abbreviation: config.name,
            name: config.description ?? config.name,
            language: Value(config.lang ?? 'en'),
            about: config.about != null
                ? Value(config.about)
                : const Value.absent(),
          ),
          mode: InsertMode.insertOrReplace,
        );

    final sourceType = config.sourceType;
    var bookOrder = 0;
    var verseCount = 0;

    for (final testament in const ['OT', 'NT']) {
      final reader = testament == 'OT' ? ot : nt;
      if (reader == null) continue;
      final books = versification.booksFor(testament);

      for (var bi = 0; bi < books.length; bi++) {
        final book = books[bi];

        // Collect this book's verses first; only create the book row if the
        // module actually contains text for it.
        final rows = <VersesCompanion>[];
        for (var chapter = 1; chapter <= book.chapterCount; chapter++) {
          final verses = book.versesPerChapter[chapter - 1];
          for (var verse = 1; verse <= verses; verse++) {
            final index =
                versification.indexOf(testament, bi, chapter, verse);
            if (index == null) continue;
            final raw = reader.entryAt(index);
            if (raw == null || raw.trim().isEmpty) continue;

            final parsed = _parseEntry(raw, sourceType);
            if (parsed.text.isEmpty) continue;

            rows.add(VersesCompanion.insert(
              bookId: 0, // patched once the book id is known
              chapter: chapter,
              verse: verse,
              textContent: parsed.text,
              segments:
                  jsonEncode(parsed.segments.map((s) => s.toJson()).toList()),
            ));
          }
        }
        if (rows.isEmpty) continue;

        bookOrder++;
        final bookId = await store.into(store.books).insert(
              BooksCompanion.insert(
                versionId: vid,
                name: book.name,
                bookOrder: bookOrder,
                testament: testament,
              ),
            );

        await store.batch((batch) {
          for (final row in rows) {
            batch.insert(store.verses, row.copyWith(bookId: Value(bookId)));
          }
        });
        verseCount += rows.length;
      }
    }

    if (verseCount == 0) {
      await store.deleteVersion(vid);
      throw Exception(
        'No verses found in SWORD module "${config.name}" — it may use an '
        'unsupported versification or be empty.',
      );
    }

    await store.customStatement(
      '''
      INSERT INTO content_search(type, reference_id, text_content)
      SELECT 'verse', v.id, v.text_content
      FROM verses v
      JOIN books b ON v.book_id = b.id
      WHERE b.version_id = ?
    ''',
      [vid],
    );
  }

  /// Parse a single verse's raw entry according to the module's [sourceType].
  /// TEI is rejected earlier; everything else maps to a per-source filter.
  ParsedVerseEntry _parseEntry(String raw, SwordSourceType sourceType) {
    switch (sourceType) {
      case SwordSourceType.osis:
        return parseOsisFragment(raw);
      case SwordSourceType.gbf:
        return parseGbfFragment(raw);
      case SwordSourceType.thml:
        return parseThmlFragment(raw);
      case SwordSourceType.tei:
      case SwordSourceType.plaintext:
        return _plainEntry(raw);
    }
  }

  /// Treat a plaintext entry literally: collapse whitespace, single segment.
  ParsedVerseEntry _plainEntry(String raw) {
    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return ParsedVerseEntry(
        text, text.isEmpty ? const [] : [VerseSegment(text: text)]);
  }
}
