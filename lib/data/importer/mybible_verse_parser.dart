import '../models/verse_segment.dart';

/// Plain, searchable text for a verse: strips MyBible inline markup (Strong's
/// numbers, footnotes, formatting tags) so the FTS index isn't polluted and
/// phrase search isn't broken by tag tokens interleaved between words. OSIS
/// verses are already plain, and the parser leaves plain text untouched, so
/// this is safe to apply to any verse's stored text.
String mybibleVersePlainText(String raw) {
  return MyBibleVerseParser()
      .parseVerse(raw)
      .map((s) => s.text)
      .join('')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class MyBibleVerseParser {
  bool _inItalic = false;
  bool _inJesusWords = false;
  bool _inStrongsNumber = false; // To hide standalone Strong's numbers
  bool _inFootnote = false;

  List<VerseSegment> parseVerse(String text) {
    // Regex to match XML/HTML like tags. E.g. <pb/>, <t>, </i>, <S n="123">
    final regex = RegExp(r'<(/?[a-zA-Z0-9]+)([^>]*)>');
    final List<VerseSegment> segments = [];
    int lastMatchEnd = 0;

    // Replace standalone & with &amp; if needed, but since we just output text,
    // we can ignore HTML entity decoding for now or do it if required.
    // MyBible often uses things like `<pb/>`

    for (final match in regex.allMatches(text)) {
      final textBefore = text.substring(lastMatchEnd, match.start);
      if (textBefore.isNotEmpty) {
        if (_inStrongsNumber) {
          segments.add(
            VerseSegment(
              strongs: _decodeEntities(textBefore),
            ),
          );
        } else if (_inFootnote) {
          segments.add(
            VerseSegment(
              isFootnote: true,
              footnoteText: _decodeEntities(textBefore),
            ),
          );
        } else {
          segments.add(
            VerseSegment(
              text: _decodeEntities(textBefore),
              isItalic: _inItalic,
              isJesusWords: _inJesusWords,
            ),
          );
        }
      }

      final fullTag = match.group(1)!.toLowerCase();
      final attrsStr = match.group(2) ?? '';
      final isClosing = fullTag.startsWith('/');
      final isSelfClosing = attrsStr.endsWith('/');
      final tagName = isClosing ? fullTag.substring(1) : fullTag;

      if (tagName == 'pb') {
        segments.add(const VerseSegment(isParagraphBreak: true));
      } else if (tagName == 'br') {
        segments.add(const VerseSegment(isLineBreak: true));
      } else if (tagName == 'i') {
        if (!isSelfClosing) _inItalic = !isClosing;
      } else if (tagName == 't' || tagName == 'j') {
        if (!isSelfClosing) _inJesusWords = !isClosing;
      } else if (tagName == 's') {
        if (!isClosing && !isSelfClosing) {
          final nMatch = RegExp(r'n="([^"]+)"', caseSensitive: false).firstMatch(attrsStr);
          if (nMatch != null) {
            segments.add(VerseSegment(strongs: nMatch.group(1)));
          } else {
            _inStrongsNumber = true;
          }
        } else if (isClosing) {
          _inStrongsNumber = false;
        }
      } else if (tagName == 'f') {
        if (!isSelfClosing) _inFootnote = !isClosing;
      }

      lastMatchEnd = match.end;
    }

    final textAfter = text.substring(lastMatchEnd);
    if (textAfter.isNotEmpty) {
      if (_inStrongsNumber) {
        segments.add(
          VerseSegment(
            strongs: _decodeEntities(textAfter),
          ),
        );
      } else if (_inFootnote) {
        segments.add(
          VerseSegment(
            isFootnote: true,
            footnoteText: _decodeEntities(textAfter),
          ),
        );
      } else {
        segments.add(
          VerseSegment(
            text: _decodeEntities(textAfter),
            isItalic: _inItalic,
            isJesusWords: _inJesusWords,
          ),
        );
      }
    }

    return segments;
  }

  String _decodeEntities(String input) {
    return input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }
}
