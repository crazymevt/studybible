import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/importer/mybible_importer.dart';

void main() {
  group('renderMyBibleCrossRef', () {
    test('empty input yields empty output', () {
      expect(renderMyBibleCrossRef(''), '');
    });

    test('a single link becomes a navigable token', () {
      expect(
        renderMyBibleCrossRef("<a href='B:650 1:10'>HEB 1:10</a>"),
        '{650:1:10|HEB 1:10}',
      );
    });

    test('comma-joined links keep the separator as plain text', () {
      expect(
        renderMyBibleCrossRef(
          "<a href='B:500 1:1'>JHN 1:1</a>,<a href='B:500 1:3'>3</a>",
        ),
        '{500:1:1|JHN 1:1}, {500:1:3|3}',
      );
    });

    test('semicolon-separated links are normalised', () {
      expect(
        renderMyBibleCrossRef(
          "<a href='B:730 4:11'>REV 4:11</a>; <a href='B:650 11:3'>HEB 11:3</a>; "
          "<a href='B:580 1:16'>COL 1:16</a>",
        ),
        '{730:4:11|REV 4:11}; {650:11:3|HEB 11:3}; {580:1:16|COL 1:16}',
      );
    });

    test('a verse range in the href keeps the start verse as the target', () {
      expect(
        renderMyBibleCrossRef("<a href='B:500 1:1-3'>JHN 1:1-3</a>"),
        '{500:1:1|JHN 1:1-3}',
      );
    });

    test('plain (untagged) text passes through, whitespace collapsed', () {
      expect(
        renderMyBibleCrossRef('see   also  Genesis 1'),
        'see also Genesis 1',
      );
    });
  });
}
