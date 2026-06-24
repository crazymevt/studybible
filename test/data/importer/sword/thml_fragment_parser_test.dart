import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/importer/sword/thml_fragment_parser.dart';

void main() {
  group('parseThmlFragment', () {
    test('attaches a trailing <sync> Strong\'s to the preceding word', () {
      final r = parseThmlFragment(
          'The book of Jesus<sync type="Strongs" value="G2424"/> Christ'
          '<sync type="Strongs" value="G5547"/>');
      expect(r.text, 'The book of Jesus Christ');
      expect(r.segments.firstWhere((s) => s.text.trim() == 'Jesus').strongs,
          'G2424');
      expect(r.segments.firstWhere((s) => s.text.trim() == 'Christ').strongs,
          'G5547');
    });

    test('ignores non-Strongs sync markers (e.g. morph)', () {
      final r = parseThmlFragment(
          'Jesus<sync type="Strongs" value="G2424"/>'
          '<sync type="morph" value="N-NSM"/>');
      final seg = r.segments.firstWhere((s) => s.text.trim() == 'Jesus');
      expect(seg.strongs, 'G2424'); // morph sync did not overwrite/append
    });

    test('captures <note> as a footnote kept out of plain text', () {
      final r = parseThmlFragment(
          'the earth<note>Heb. eretz</note> was without form');
      expect(r.text, 'the earth was without form');
      expect(r.text, isNot(contains('eretz')));
      expect(r.segments.singleWhere((s) => s.isFootnote).footnoteText,
          'Heb. eretz');
    });

    test('marks <i> as italic and breaks on <br/>', () {
      final r = parseThmlFragment('plain <i>added</i> words<br/>next');
      expect(r.segments.firstWhere((s) => s.text.trim() == 'added').isItalic,
          isTrue);
      expect(r.segments.any((s) => s.isLineBreak), isTrue);
      expect(r.text, 'plain added words next');
    });

    test('falls back to tag-stripping on malformed XML', () {
      // A bare ampersand is not well-formed XML; the parser must not throw.
      final r = parseThmlFragment('Tom & Jerry <b>went');
      expect(r.text, 'Tom & Jerry went');
    });
  });
}
