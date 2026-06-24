import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/importer/sword/osis_fragment_parser.dart';

void main() {
  group('parseOsisFragment', () {
    test('returns a single plain segment for untagged text', () {
      final r = parseOsisFragment('In the beginning');
      expect(r.text, 'In the beginning');
      expect(r.segments.map((s) => s.text), ['In the beginning']);
    });

    test('flattens inline markup and collapses whitespace', () {
      final r = parseOsisFragment(
          'In the <w lemma="strong:H7225">beginning</w>   God\ncreated.');
      expect(r.text, 'In the beginning God created.');
    });

    test('attaches Strong\'s numbers from <w lemma>', () {
      final r = parseOsisFragment('the <w lemma="strong:H7225">beginning</w>');
      final w = r.segments.firstWhere((s) => s.text == 'beginning');
      expect(w.strongs, 'H7225');
    });

    test('joins multiple Strong\'s lemmas', () {
      final r = parseOsisFragment(
          '<w lemma="strong:G2532 strong:G1161">and</w>');
      expect(r.segments.single.strongs, 'G2532 G1161');
    });

    test('keeps <note> text as a footnote segment, out of the verse text', () {
      final r = parseOsisFragment(
          'the earth.<note type="study">cf. John 1:1</note>');
      expect(r.text, 'the earth.');
      expect(r.text, isNot(contains('John')));
      final notes = r.segments.where((s) => s.isFootnote).toList();
      expect(notes, hasLength(1));
      expect(notes.single.footnoteText, 'cf. John 1:1');
    });

    test('marks transChange type="added" as italic', () {
      final r = parseOsisFragment('God <transChange type="added">is</transChange> love');
      final added = r.segments.firstWhere((s) => s.text.trim() == 'is');
      expect(added.isItalic, isTrue);
      expect(r.text, 'God is love');
    });

    test('marks <q who="Jesus"> as Jesus words', () {
      final r = parseOsisFragment('<q who="Jesus">I am he</q>');
      expect(r.segments.any((s) => s.isJesusWords), isTrue);
    });

    test('flattens unknown wrappers such as divineName', () {
      final r = parseOsisFragment('the <divineName>LORD</divineName> spake');
      expect(r.text, 'the LORD spake');
    });

    test('separates a canonical <title> from the following verse text', () {
      // Real KJV modules embed the Psalm superscription as a <title> in v.1;
      // without separation it merged as "David.The LORD…".
      final r = parseOsisFragment(
          '<title canonical="true">A Psalm of David.</title>'
          'The LORD is my shepherd');
      expect(r.text, 'A Psalm of David. The LORD is my shepherd');
      expect(r.segments.any((s) => s.isLineBreak), isTrue);
    });

    test('falls back to tag-stripping on malformed XML', () {
      // A bare & makes the fragment invalid XML; we still capture the text.
      final r = parseOsisFragment('Shadrach & Meshach <w>went</w>');
      expect(r.text, 'Shadrach & Meshach went');
    });
  });
}
