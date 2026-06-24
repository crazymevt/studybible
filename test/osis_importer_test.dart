import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:study_bible/data/importer/osis_importer.dart';

XmlElement _firstBookDiv(String xml) {
  final doc = XmlDocument.parse(xml);
  return doc
      .findAllElements('div')
      .firstWhere((e) => e.getAttribute('type') == 'book');
}

void main() {
  group('extractOsisBookVerses', () {
    test('container form: <verse> wraps its text', () {
      final book = _firstBookDiv('''
        <osis><osisText><div type="book" osisID="Gen">
          <chapter osisID="Gen.1">
            <verse osisID="Gen.1.1">In the beginning</verse>
            <verse osisID="Gen.1.2">And the earth</verse>
          </chapter>
        </div></osisText></osis>
      ''');

      final verses = extractOsisBookVerses(book);
      expect(verses.map((v) => (v.chapter, v.verse, v.text)), [
        (1, 1, 'In the beginning'),
        (1, 2, 'And the earth'),
      ]);
    });

    test('milestone form: sID/eID markers bracket sibling text', () {
      final book = _firstBookDiv('''
        <osis><osisText><div type="book" osisID="John">
          <chapter osisID="John.1" sID="John.1"/>
          <verse osisID="John.1.1" sID="John.1.1"/>In the beginning was the Word<verse eID="John.1.1"/>
          <verse osisID="John.1.2" sID="John.1.2"/>The same was in the beginning<verse eID="John.1.2"/>
          <chapter eID="John.1"/>
          <chapter osisID="John.3" sID="John.3"/>
          <verse osisID="John.3.16" sID="John.3.16"/>For God so loved<verse eID="John.3.16"/>
          <chapter eID="John.3"/>
        </div></osisText></osis>
      ''');

      final verses = extractOsisBookVerses(book);
      expect(verses.map((v) => (v.chapter, v.verse, v.text)), [
        (1, 1, 'In the beginning was the Word'),
        (1, 2, 'The same was in the beginning'),
        (3, 16, 'For God so loved'),
      ]);
    });

    test('inline <w> markup is flattened; <note> is kept out of the text', () {
      final book = _firstBookDiv('''
        <osis><osisText><div type="book" osisID="Gen">
          <chapter osisID="Gen.1" sID="Gen.1"/>
          <verse osisID="Gen.1.1" sID="Gen.1.1"/><w lemma="strong:H7225">In the beginning</w> God<note type="study">a note</note> created<verse eID="Gen.1.1"/>
          <chapter eID="Gen.1"/>
        </div></osisText></osis>
      ''');

      final verses = extractOsisBookVerses(book);
      expect(verses.length, 1);
      expect(verses.first.text, 'In the beginning God created');
      expect(verses.first.text, isNot(contains('a note')));
      expect(verses.first.segmentsJson, contains('a note')); // footnote segment
    });

    test('empty / unparseable book yields no verses', () {
      final book = _firstBookDiv(
        '<osis><osisText><div type="book" osisID="Gen"></div></osisText></osis>',
      );
      expect(extractOsisBookVerses(book), isEmpty);
    });
  });
}
