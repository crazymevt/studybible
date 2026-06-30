import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/content_providers.dart';

void main() {
  group('strongsLookupForms', () {
    test('a padded module token resolves an unpadded lexicon headword', () {
      // The reader emits "H07225" (CrossWire OSIS); a lexicon may key it
      // "H7225". The candidate set must contain that form.
      expect(strongsLookupForms('H07225'), contains('H7225'));
    });

    test('an unpadded token resolves a padded headword', () {
      final forms = strongsLookupForms('H7225');
      expect(forms, contains('H07225'));
      expect(forms, contains('H7225'));
    });

    test('offers prefixed and bare numeric forms', () {
      final forms = strongsLookupForms('G2532');
      expect(forms, contains('G2532'));
      expect(forms, contains('2532'));
      expect(forms, contains('02532'));
    });

    test('normalises a lowercase prefix to upper case', () {
      expect(strongsLookupForms('h430'), contains('H430'));
      expect(strongsLookupForms('h430'), contains('H0430'));
    });

    test('a bare number is treated as a Strong\'s value', () {
      expect(strongsLookupForms('430'), contains('430'));
      expect(strongsLookupForms('430'), contains('0430'));
    });

    test('a plain word is not a Strong\'s number', () {
      expect(strongsLookupForms('beginning'), isEmpty);
      expect(strongsLookupForms('love'), isEmpty);
      expect(strongsLookupForms(''), isEmpty);
      // A bare prefix with no digits is not a lookup token.
      expect(strongsLookupForms('H'), isEmpty);
    });
  });
}
