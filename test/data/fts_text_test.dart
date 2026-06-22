import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/fts_text.dart';

void main() {
  group('stripMarkupForIndex', () {
    test('removes HTML tags, keeping the text', () {
      expect(stripMarkupForIndex('<p>Hello <b>world</b></p>'), 'Hello world');
    });

    test('drops attribute values / junk ids embedded in tags', () {
      expect(
        stripMarkupForIndex('<div id="jessdvffhtl1t1cputsp">Grace</div>'),
        'Grace',
      );
    });

    test('decodes common HTML entities', () {
      expect(
        stripMarkupForIndex('Shadrach &amp; &lt;name&gt; &quot;x&quot;'),
        'Shadrach & <name> "x"',
      );
    });

    test('collapses whitespace left by tag removal', () {
      expect(
        stripMarkupForIndex('<h3>John 1:1</h3>\n<p>The   Word</p>'),
        'John 1:1 The Word',
      );
    });

    test('leaves plain text unchanged', () {
      expect(stripMarkupForIndex('In the beginning'), 'In the beginning');
    });

    test('handles empty string', () {
      expect(stripMarkupForIndex(''), '');
    });
  });

  group('deltaToPlainText', () {
    test('extracts text from Delta insert ops', () {
      expect(
        deltaToPlainText(
          '[{"insert":"Grace and "},{"insert":"truth","attributes":{"bold":true}}]',
        ),
        'Grace and truth',
      );
    });

    test('skips embed (non-string) inserts', () {
      expect(
        deltaToPlainText('[{"insert":{"image":"x.png"}},{"insert":"caption"}]'),
        'caption',
      );
    });

    test('collapses trailing newlines/whitespace', () {
      expect(deltaToPlainText('[{"insert":"Line one\\n\\n"}]'), 'Line one');
    });

    test('falls back to the input when not valid Delta JSON', () {
      expect(deltaToPlainText('just plain text'), 'just plain text');
    });

    test('handles empty string', () {
      expect(deltaToPlainText(''), '');
    });
  });
}
