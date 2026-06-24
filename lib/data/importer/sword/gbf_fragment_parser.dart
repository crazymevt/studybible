import 'parsed_verse_entry.dart';
import 'verse_segment_builder.dart';

/// Parses a single verse's **GBF** (General Bible Format) fragment into plain
/// text plus segments, mirroring what `parseOsisFragment` does for OSIS.
///
/// GBF is the older token-based SWORD markup: angle-bracket control codes
/// interleaved with text rather than nested XML. The codes handled here:
///
/// * `<RF>…<Rf>` — a footnote/cross-ref; captured as a footnote segment and
///   kept out of the plain (searchable) text.
/// * `<FI>…<Fi>` — italic/added words; `<FR>…<Fr>` — words of Jesus (red).
/// * `<WGnnnn>` / `<WHnnnn>` — a Strong's number. GBF places the code *after*
///   the word it annotates, so it is attached to the preceding word.
///   Morphology codes (`<WTxxx>`) are ignored.
/// * `<CM>` — paragraph break; `<CL>`/`<Ts>`/`<Te>` — line break.
///
/// Any other `<…>` code is dropped (its surrounding text still flows through),
/// so an unrecognised tag degrades to plain text rather than corrupting it.
ParsedVerseEntry parseGbfFragment(String fragment) {
  final b = VerseSegmentBuilder();
  final footnote = StringBuffer();

  var italic = false;
  var jesus = false;
  var inFootnote = false;

  void closeFootnote() {
    inFootnote = false;
    b.addFootnote(footnote.toString());
    footnote.clear();
  }

  for (final token in _tokenize(fragment)) {
    if (!token.startsWith('<')) {
      if (inFootnote) {
        footnote.write(token);
      } else {
        b.addText(token, italic: italic, jesus: jesus);
      }
      continue;
    }
    final inner = token.substring(1, token.length - 1).trim();
    if (inner.isEmpty) continue;
    final name = inner.split(RegExp(r'\s')).first;

    switch (name) {
      case 'RF':
        inFootnote = true;
        footnote.clear();
      case 'Rf':
        closeFootnote();
      case 'FI':
        italic = true;
      case 'Fi':
        italic = false;
      case 'FR':
        jesus = true;
      case 'Fr':
        jesus = false;
      case 'CM':
        b.addParagraphBreak();
      case 'CL':
      case 'Ts':
      case 'Te':
        b.addLineBreak();
      default:
        final m = RegExp(r'^W([GH]\d+)$').firstMatch(name);
        if (m != null) b.attachStrongs(m.group(1)!);
        // Any other code (TS, RB, RX, font codes, …) is dropped.
    }
  }
  // A fragment that ends mid-footnote still yields its note text.
  if (inFootnote) closeFootnote();

  return b.build();
}

/// Split [fragment] into an alternating stream of text runs and `<…>` tags.
Iterable<String> _tokenize(String fragment) sync* {
  final tag = RegExp(r'<[^>]*>');
  var pos = 0;
  for (final m in tag.allMatches(fragment)) {
    if (m.start > pos) yield fragment.substring(pos, m.start);
    yield m.group(0)!;
    pos = m.end;
  }
  if (pos < fragment.length) yield fragment.substring(pos);
}
