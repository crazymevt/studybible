import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/importer/mybible_verse_parser.dart';

void main() {
  group('mybibleVersePlainText', () {
    test('plain text is returned unchanged', () {
      expect(
        mybibleVersePlainText('In the beginning was the Word'),
        'In the beginning was the Word',
      );
    });

    test("standalone Strong's numbers are excluded", () {
      // Strong's numbers must not be indexed, and must not split adjacent words.
      expect(
        mybibleVersePlainText('In the <S>1722</S>beginning was the Word'),
        'In the beginning was the Word',
      );
    });

    test('footnote text is excluded', () {
      expect(
        mybibleVersePlainText('the Word<f>a footnote</f> was God'),
        'the Word was God',
      );
    });

    test('formatting tags are stripped but their text is kept', () {
      expect(
        mybibleVersePlainText('the <i>Word</i> was God'),
        'the Word was God',
      );
    });

    test('collapses whitespace', () {
      expect(mybibleVersePlainText('the   Word\n was'), 'the Word was');
    });
  });
}
