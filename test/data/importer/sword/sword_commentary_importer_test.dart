import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/sword/sword_config.dart';
import 'package:study_bible/data/importer/sword/sword_versification.dart';
import 'package:study_bible/data/importer/sword/sword_ztext_reader.dart';
import 'package:study_bible/data/importer/sword/sword_commentary_importer.dart';

Uint8List _le32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();
Uint8List _le16(int v) =>
    (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List();
Uint8List _concat(List<List<int>> parts) {
  final b = BytesBuilder();
  for (final part in parts) {
    b.add(part);
  }
  return b.toBytes();
}

/// Build a single-block zCom/zText reader whose entries are [slotToFragment].
SwordZTextReader _reader(Map<int, String> slotToFragment) {
  final order = slotToFragment.keys.toList()..sort();
  final buffer = StringBuffer();
  final offsets = <int, ({int offset, int len})>{};
  for (final slot in order) {
    final bytes = utf8.encode(slotToFragment[slot]!);
    offsets[slot] =
        (offset: utf8.encode(buffer.toString()).length, len: bytes.length);
    buffer.write(slotToFragment[slot]!);
  }
  final block = utf8.encode(buffer.toString());
  final comp = zlib.encode(block);
  final maxSlot = order.last;
  final verseRecords = <List<int>>[];
  for (var i = 0; i <= maxSlot; i++) {
    final e = offsets[i];
    verseRecords.add(e == null
        ? _concat([_le32(0), _le32(0), _le16(0)])
        : _concat([_le32(0), _le32(e.offset), _le16(e.len)]));
  }
  return SwordZTextReader(
    verseIndex: _concat(verseRecords),
    blockIndex: _concat([_le32(0), _le32(comp.length), _le32(block.length)]),
    textData: Uint8List.fromList(comp),
    compressType: SwordCompressType.zip,
  );
}

void main() {
  late ContentStore store;
  setUp(() => store = ContentStore(NativeDatabase.memory()));
  tearDown(() => store.close());

  final kjv = kjvVersification;

  final config = SwordConfig.parse('''
[MHCC]
ModDrv=zCom
SourceType=OSIS
CompressType=ZIP
BlockType=BOOK
Versification=KJV
Description=Matthew Henry Concise
About=A test commentary.
''');

  // Commentary notes on Genesis 1:1 (OT) and Matthew 1:1 (NT).
  SwordZTextReader otReader() => _reader({
        kjv.indexOf('OT', 0, 1, 1)!:
            '<p>The first verse.</p><p>A second paragraph<note>cf. John 1</note></p>',
      });
  SwordZTextReader ntReader() => _reader({
        kjv.indexOf('NT', 0, 1, 1)!: 'The genealogy record.',
      });

  test('imports book- and chapter-intro slots as null coordinates', () async {
    final reader = _reader({
      kjv.bookIntroIndex('OT', 0)!: '<p>Genesis: book introduction.</p>',
      kjv.chapterIntroIndex('OT', 0, 1)!: '<p>Chapter 1 overview.</p>',
      kjv.indexOf('OT', 0, 1, 1)!: '<p>On verse one.</p>',
    });
    await SwordCommentaryImporter(store).importCommentary(config, ot: reader);

    final entries = await (store.select(store.commentaryEntries)
          ..where((e) => e.bookName.equals('Genesis')))
        .get();
    expect(entries, hasLength(3));

    final bookIntro =
        entries.singleWhere((e) => e.chapter == null && e.verse == null);
    expect(bookIntro.textContent, contains('book introduction'));

    final chapterIntro =
        entries.singleWhere((e) => e.chapter == 1 && e.verse == null);
    expect(chapterIntro.textContent, contains('Chapter 1 overview'));

    final verse = entries.singleWhere((e) => e.chapter == 1 && e.verse == 1);
    expect(verse.textContent, contains('On verse one'));
  });

  test('imports commentary metadata and entries', () async {
    await SwordCommentaryImporter(store)
        .importCommentary(config, ot: otReader(), nt: ntReader());

    final commentary = await store.select(store.commentaries).getSingle();
    expect(commentary.abbreviation, 'MHCC');
    expect(commentary.name, 'Matthew Henry Concise');
    expect(commentary.about, 'A test commentary.');

    final entries = await (store.select(store.commentaryEntries)
          ..orderBy([(e) => OrderingTerm(expression: e.bookName)]))
        .get();
    expect(entries, hasLength(2));
    final gen = entries.firstWhere((e) => e.bookName == 'Genesis');
    expect(gen.chapter, 1);
    expect(gen.verse, 1);
  });

  test('serialises entry markup to HTML paragraphs, footnotes inline', () async {
    await SwordCommentaryImporter(store)
        .importCommentary(config, ot: otReader(), nt: ntReader());

    final gen = await (store.select(store.commentaryEntries)
          ..where((e) => e.bookName.equals('Genesis')))
        .getSingle();
    expect(gen.textContent, contains('<p>The first verse.</p>'));
    expect(gen.textContent, contains('<p>A second paragraph'));
    expect(gen.textContent, contains('[cf. John 1]')); // footnote inlined
  });

  test('populates the FTS index with markup stripped', () async {
    await SwordCommentaryImporter(store)
        .importCommentary(config, ot: otReader(), nt: ntReader());

    final rows = await store.customSelect(
      "SELECT reference_id FROM content_search "
      "WHERE type = 'commentary' AND content_search MATCH 'genealogy'",
    ).get();
    expect(rows, hasLength(1));
    // The HTML markup itself (tag/attribute tokens) must not be indexed.
    final tagRows = await store.customSelect(
      "SELECT reference_id FROM content_search "
      "WHERE type = 'commentary' AND content_search MATCH 'span'",
    ).get();
    expect(tagRows, isEmpty);
  });

  test('rejects a non-commentary driver', () async {
    final bible = SwordConfig.parse('[X]\nModDrv=zText\nSourceType=OSIS');
    expect(
      () => SwordCommentaryImporter(store)
          .importCommentary(bible, ot: otReader()),
      throwsUnsupportedError,
    );
  });

  test('re-importing replaces the prior commentary', () async {
    final importer = SwordCommentaryImporter(store);
    await importer.importCommentary(config, ot: otReader(), nt: ntReader());
    await importer.importCommentary(config, ot: otReader(), nt: ntReader());

    expect(await store.select(store.commentaries).get(), hasLength(1));
    expect(await store.select(store.commentaryEntries).get(), hasLength(2));
  });

  group('importFromDirectory', () {
    test('imports an uncompressed RawCom module (ot + ot.vss)', () async {
      final root = await Directory.systemTemp.createTemp('sword_rawcom');
      addTearDown(() => root.delete(recursive: true));
      final dataDir =
          Directory(p.join(root.path, 'modules', 'comments', 'rawcom', 'test'))
            ..createSync(recursive: true);

      const note = 'A plain commentary note.';
      final slot = kjv.indexOf('OT', 0, 1, 1)!;
      final bytes = utf8.encode(note);
      final records = <List<int>>[];
      for (var i = 0; i <= slot; i++) {
        records.add(i == slot
            ? _concat([_le32(0), _le16(bytes.length)])
            : _concat([_le32(0), _le16(0)]));
      }
      File(p.join(dataDir.path, 'ot')).writeAsBytesSync(bytes);
      File(p.join(dataDir.path, 'ot.vss')).writeAsBytesSync(_concat(records));

      final cfg = SwordConfig.parse('''
[DTN]
DataPath=./modules/comments/rawcom/test/
ModDrv=RawCom
SourceType=plain
Versification=KJV
Description=Raw Commentary
''');

      await SwordCommentaryImporter(store).importFromDirectory(root, cfg);

      final gen = await (store.select(store.commentaryEntries)
            ..where((e) => e.bookName.equals('Genesis')))
          .getSingle();
      expect(gen.textContent, '<p>A plain commentary note.</p>');
    });
  });
}
