import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/scripture/scripture_parser.dart';

void main() {
  group('ScriptureParser', () {
    test('parses a simple "Book chapter:verse" reference', () {
      final ref = ScriptureParser.parse('John 3:16');
      expect(ref, isNotNull);
      expect(ref!.book, 'John');
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parses a numbered book name', () {
      final ref = ScriptureParser.parse('1 John 2:3');
      expect(ref, isNotNull);
      expect(ref!.book, '1 John');
      expect(ref.chapter, 2);
      expect(ref.verse, 3);
    });

    test('parses a numbered book name without a space', () {
      final ref = ScriptureParser.parse('1John 2:3');
      expect(ref, isNotNull);
      expect(ref!.book, '1John');
      expect(ref.chapter, 2);
      expect(ref.verse, 3);
    });

    test('trims surrounding whitespace', () {
      final ref = ScriptureParser.parse('  John 3:16  ');
      expect(ref, isNotNull);
      expect(ref!.book, 'John');
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('returns null when the verse is missing', () {
      expect(ScriptureParser.parse('John 3'), isNull);
    });

    test('returns null for a bare book name', () {
      expect(ScriptureParser.parse('John'), isNull);
    });

    test('returns null for unparseable input', () {
      expect(ScriptureParser.parse('not a reference'), isNull);
      expect(ScriptureParser.parse(''), isNull);
    });

    test(
      'does not support multi-word book names (documents current limitation)',
      () {
        expect(ScriptureParser.parse('Song of Solomon 2:1'), isNull);
      },
    );

    test('toString round-trips the reference', () {
      final ref = ScriptureParser.parse('John 3:16');
      expect(ref.toString(), 'John 3:16');
    });
  });
}
