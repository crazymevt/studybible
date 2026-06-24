import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../content_store.dart';
import 'segment_html.dart';
import 'sword_config.dart';
import 'sword_rawtext_reader.dart';
import 'sword_source_parser.dart';
import 'sword_verse_reader.dart';
import 'sword_versification.dart';
import 'sword_ztext_reader.dart';

/// Imports a SWORD commentary module (`zCom`/`zCom4` compressed, or
/// `RawCom`/`RawCom4` uncompressed) into the content store's
/// `commentaries`/`commentary_entries` tables.
///
/// A commentary uses the same verse-keyed `zVerse`/`RawVerse` backend as a
/// Bible — the same testament files, the same positional verse index, the same
/// reserved leading slots — so it reuses [SwordZTextReader]/[SwordRawTextReader]
/// and walks the versification exactly like the Bible importer. Each present
/// entry is parsed with its `SourceType` filter and serialised to simple HTML
/// (the commentary panel renders with `HtmlWidget`).
///
/// Maps per-verse entries plus the book- and chapter-intro ("verse 0") slots:
/// book intros are stored with null chapter+verse and chapter intros with a
/// chapter and null verse, matching the commentary panel's intro/chapter
/// queries. Scope: the `KJV` versification.
class SwordCommentaryImporter {
  final ContentStore store;

  SwordCommentaryImporter(this.store);

  /// Import the module described by [config], reading from the module's
  /// directory tree rooted at [moduleRoot].
  Future<void> importFromDirectory(
    Directory moduleRoot,
    SwordConfig config,
  ) async {
    final rel = (config.dataPath ?? '').replaceFirst(RegExp(r'^\./'), '');
    final dataDir = Directory(p.normalize(p.join(moduleRoot.path, rel)));

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
    await importCommentary(config, ot: ot, nt: nt);
  }

  /// Core import: walk the versification and write the commentary backed by the
  /// supplied testament readers (either may be null). Separated from file
  /// resolution so it can be driven from in-memory readers in tests.
  Future<void> importCommentary(
    SwordConfig config, {
    SwordVerseReader? ot,
    SwordVerseReader? nt,
  }) async {
    if (!config.modDrv.isCommentary) {
      throw UnsupportedError(
        'SwordCommentaryImporter handles commentary modules (zCom/RawCom); '
        'got ModDrv "${config.value('ModDrv')}".',
      );
    }
    final versification = swordVersificationByName(config.versification);
    if (versification == null) {
      throw UnsupportedError(
        'SWORD versification "${config.versification}" is not yet supported; '
        'only KJV is available.',
      );
    }

    final abbr = config.name.toUpperCase();
    final existing = await (store.select(store.commentaries)
          ..where((c) => c.abbreviation.equals(abbr)))
        .get();
    for (final e in existing) {
      await store.deleteCommentary(e.id);
    }

    final commentaryId = await store.into(store.commentaries).insert(
          CommentariesCompanion.insert(
            abbreviation: abbr,
            name: config.description ?? config.name,
            about: config.about != null
                ? Value(config.about)
                : const Value.absent(),
          ),
        );

    final sourceType = config.sourceType;
    var entryCount = 0;

    for (final testament in const ['OT', 'NT']) {
      final reader = testament == 'OT' ? ot : nt;
      if (reader == null) continue;
      final books = versification.booksFor(testament);

      for (var bi = 0; bi < books.length; bi++) {
        final book = books[bi];
        final rows = <CommentaryEntriesCompanion>[];

        // Read the entry at [index]; if present, append a row for the given
        // (chapter, verse) coordinate. Book intros use null chapter+verse;
        // chapter intros use a chapter with null verse (matches the MyBible
        // importer and the commentary panel's intro/chapter queries).
        void addSlot(int? index, {int? chapter, int? verse}) {
          if (index == null) return;
          final raw = reader.entryAt(index);
          if (raw == null || raw.trim().isEmpty) return;
          final html = segmentsToHtml(parseSwordSource(raw, sourceType).segments);
          if (html.isEmpty) return;
          rows.add(CommentaryEntriesCompanion.insert(
            commentaryId: commentaryId,
            bookName: book.name,
            chapter: Value(chapter),
            verse: Value(verse),
            textContent: html,
          ));
        }

        // Book-level intro material.
        addSlot(versification.bookIntroIndex(testament, bi));

        for (var chapter = 1; chapter <= book.chapterCount; chapter++) {
          // Chapter-level intro material.
          addSlot(versification.chapterIntroIndex(testament, bi, chapter),
              chapter: chapter);

          final verses = book.versesPerChapter[chapter - 1];
          for (var verse = 1; verse <= verses; verse++) {
            addSlot(versification.indexOf(testament, bi, chapter, verse),
                chapter: chapter, verse: verse);
          }
        }
        if (rows.isEmpty) continue;
        await store.batch((batch) => batch.insertAll(store.commentaryEntries, rows));
        entryCount += rows.length;
      }
    }

    if (entryCount == 0) {
      await store.deleteCommentary(commentaryId);
      throw Exception(
        'No entries found in SWORD commentary "${config.name}" — it may use an '
        'unsupported versification or be empty.',
      );
    }

    await store.indexStrippedEntries(
      'commentary',
      'commentary_entries',
      'commentary_id',
      commentaryId,
    );
  }
}
