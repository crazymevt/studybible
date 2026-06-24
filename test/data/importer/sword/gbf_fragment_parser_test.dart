import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/importer/sword/gbf_fragment_parser.dart';

void main() {
  group('parseGbfFragment', () {
    test('attaches trailing Strong\'s codes to the preceding word', () {
      final r = parseGbfFragment(
          'In the beginning<WH7225> God<WH430> created<WH1254>');
      expect(r.text, 'In the beginning God created');

      String? strongsFor(String word) => r.segments
          .firstWhere((s) => s.text.trim() == word)
          .strongs;
      expect(strongsFor('beginning'), 'H7225');
      expect(strongsFor('God'), 'H430');
      expect(strongsFor('created'), 'H1254');
      // The leading words carry no Strong's.
      expect(r.segments.first.strongs, isNull);
    });

    test('merges two codes on the same word', () {
      final r = parseGbfFragment('Jesus<WG2424><WG5547>');
      final seg = r.segments.firstWhere((s) => s.text.trim() == 'Jesus');
      expect(seg.strongs, 'G2424 G5547');
    });

    test('captures <RF>…<Rf> as a footnote kept out of plain text', () {
      final r = parseGbfFragment('the earth<RF>Heb. eretz<Rf> was void');
      expect(r.text, 'the earth was void');
      expect(r.text, isNot(contains('eretz')));
      final note = r.segments.singleWhere((s) => s.isFootnote);
      expect(note.footnoteText, 'Heb. eretz');
    });

    test('marks italic (<FI>) and Jesus words (<FR>)', () {
      final r = parseGbfFragment('he said <FR>Follow me<Fr> to <FI>them<Fi>');
      expect(r.segments.firstWhere((s) => s.text.contains('Follow')).isJesusWords,
          isTrue);
      expect(
          r.segments.firstWhere((s) => s.text.trim() == 'them').isItalic, isTrue);
    });

    test('emits a paragraph break for <CM> and keeps text flowing', () {
      final r = parseGbfFragment('verse one<CM>verse two');
      expect(r.text, 'verse one verse two');
      expect(r.segments.any((s) => s.isParagraphBreak), isTrue);
    });

    test('drops unrecognised codes, leaving the surrounding text', () {
      final r = parseGbfFragment('the LORD<RX 1.2.3> spoke');
      expect(r.text, 'the LORD spoke');
    });
  });
}
