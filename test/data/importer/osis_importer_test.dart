import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/osis_importer.dart';
import 'package:study_bible/data/models/verse_segment.dart';

/// A minimal but representative OSIS document: a work header with a title,
/// one OT and one NT book, nested inline markup (`<w>`), and a `<note>` that
/// must be stripped from the indexed text.
const _osisXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
  <osisText osisIDWork="Test" xml:lang="en">
    <header>
      <work osisWork="Test">
        <title>Test Standard Version</title>
      </work>
    </header>
    <div type="book" osisID="Gen">
      <chapter osisID="Gen.1">
        <verse osisID="Gen.1.1">In the <w lemma="strong:H7225">beginning</w>
          God created the   heavens and the earth.<note type="study">cf. John 1:1</note></verse>
        <verse osisID="Gen.1.2">And the earth was without form.</verse>
      </chapter>
    </div>
    <div type="book" osisID="Matt">
      <chapter osisID="Matt.1">
        <verse osisID="Matt.1.1">The book of the genealogy of Jesus Christ.</verse>
      </chapter>
    </div>
  </osisText>
</osis>
''';

void main() {
  late ContentStore store;
  late Directory tmpDir;
  late File osisFile;

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());
    tmpDir = await Directory.systemTemp.createTemp('osis_test');
    osisFile = File('${tmpDir.path}/test.xml');
    await osisFile.writeAsString(_osisXml);
  });

  tearDown(() async {
    await store.close();
    await tmpDir.delete(recursive: true);
  });

  Future<List<Verse>> versesFor(String bookName) async {
    final book = await (store.select(store.books)
          ..where((b) => b.name.equals(bookName)))
        .getSingle();
    return (store.select(store.verses)
          ..where((v) => v.bookId.equals(book.id))
          ..orderBy([(v) => OrderingTerm(expression: v.verse)]))
        .get();
  }

  test('imports the version, preferring the work <title> over the argument',
      () async {
    await OsisImporter(store)
        .importOsisFile(osisFile, 'tsv', 'Fallback Title', 'en');

    final version = await store.select(store.versions).getSingle();
    expect(version.id, 'TSV', reason: 'version id is upper-cased');
    expect(version.abbreviation, 'tsv');
    expect(version.name, 'Test Standard Version');
    expect(version.language, 'en');
  });

  test('imports books with canonical names and testament', () async {
    await OsisImporter(store).importOsisFile(osisFile, 'tsv', 'TSV', 'en');

    final books = await (store.select(store.books)
          ..orderBy([(b) => OrderingTerm(expression: b.bookOrder)]))
        .get();
    expect(books.map((b) => b.name), ['Genesis', 'Matthew']);
    expect(books.map((b) => b.testament), ['OT', 'NT']);
    expect(books.map((b) => b.bookOrder), [1, 2]);
  });

  test('flattens inline markup but keeps <note> text out of the verse',
      () async {
    await OsisImporter(store).importOsisFile(osisFile, 'tsv', 'TSV', 'en');

    final gen = await versesFor('Genesis');
    expect(gen.map((v) => v.verse), [1, 2]);
    expect(gen.every((v) => v.chapter == 1), isTrue);

    // <w> text is flattened inline; the <note> text is excluded; runs of
    // whitespace collapse to a single space.
    expect(
      gen.first.textContent,
      'In the beginning God created the heavens and the earth.',
    );
    expect(gen.first.textContent, isNot(contains('John 1:1')));
    expect(gen.first.textContent, isNot(contains('   ')));
  });

  test('imports each <note> as a footnote segment, not inline verse text',
      () async {
    await OsisImporter(store).importOsisFile(osisFile, 'tsv', 'TSV', 'en');

    final gen = await versesFor('Genesis');
    final segments = (jsonDecode(gen.first.segments) as List)
        .map((e) => VerseSegment.fromJson(e as Map<String, dynamic>))
        .toList();

    final footnotes = segments.where((s) => s.isFootnote).toList();
    expect(footnotes, hasLength(1));
    expect(footnotes.single.footnoteText, 'cf. John 1:1');

    // The scripture text segments carry no footnote text.
    final textSegs = segments.where((s) => !s.isFootnote);
    expect(textSegs.map((s) => s.text).join(), isNot(contains('John 1:1')));

    // The verse without a note has no footnote segment.
    final v2 = (jsonDecode(gen[1].segments) as List)
        .map((e) => VerseSegment.fromJson(e as Map<String, dynamic>));
    expect(v2.any((s) => s.isFootnote), isFalse);
  });

  test('populates the FTS search index for imported verses', () async {
    await OsisImporter(store).importOsisFile(osisFile, 'tsv', 'TSV', 'en');

    final rows = await store.customSelect(
      "SELECT reference_id FROM content_search "
      "WHERE type = 'verse' AND content_search MATCH 'genealogy'",
    ).get();
    expect(rows, hasLength(1));
  });

  test('re-importing the same version replaces the prior rows', () async {
    final importer = OsisImporter(store);
    await importer.importOsisFile(osisFile, 'tsv', 'TSV', 'en');
    await importer.importOsisFile(osisFile, 'tsv', 'TSV', 'en');

    final versions = await store.select(store.versions).get();
    expect(versions, hasLength(1), reason: 'deleteVersion clears the old rows');
    expect(await versesFor('Genesis'), hasLength(2));
  });
}
