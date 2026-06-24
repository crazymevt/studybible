import 'package:xml/xml.dart';

import '../../models/verse_segment.dart';

/// The plain text and rich segments parsed out of a single verse.
class ParsedOsisEntry {
  /// Markup-free verse text, whitespace collapsed — suitable for the search
  /// index and for `verses.textContent`.
  final String text;

  /// Rich segments (Strong's numbers, added/italic words, footnotes) for
  /// `verses.segments`.
  final List<VerseSegment> segments;

  const ParsedOsisEntry(this.text, this.segments);
}

/// Parses a single verse's OSIS fragment into plain text plus [VerseSegment]s.
///
/// Unlike a full OSIS document (handled by the OSIS importer's
/// `extractOsisBookVerses`), a SWORD module stores one self-contained OSIS
/// *fragment* per verse — e.g.
/// `In the <w lemma="strong:H7225">beginning</w> God created…`. This adapts the
/// same conventions to that fragment form: inline markup is flattened into the
/// running text, `<note>`s become footnote segments kept out of the plain text
/// (so they never pollute search), `<w lemma="strong:…">` carries Strong's
/// numbers, and `<transChange type="added">`/`<hi>` mark italic/added words.
///
/// The fragment is wrapped and XML-parsed; if it is not well-formed (stray
/// `&`/`<`, etc.) the parser falls back to crude tag-stripping so the verse is
/// still captured as plain text.
ParsedOsisEntry parseOsisFragment(String fragment) {
  final segments = <VerseSegment>[];
  final plain = StringBuffer();

  void addText(String raw,
      {required bool italic, required bool jesus, String? strongs}) {
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return;
    segments.add(VerseSegment(
      text: collapsed,
      isItalic: italic,
      isJesusWords: jesus,
      strongs: strongs,
    ));
    plain.write(collapsed);
  }

  void walk(XmlNode node,
      {required bool italic, required bool jesus, String? strongs}) {
    for (final child in node.children) {
      if (child is XmlText) {
        addText(child.value, italic: italic, jesus: jesus, strongs: strongs);
        continue;
      }
      if (child is! XmlElement) continue;

      switch (child.localName) {
        case 'note':
          // Footnotes/cross-refs: capture as a segment, never as verse text.
          final t = child.innerText.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (t.isNotEmpty) {
            segments.add(VerseSegment(isFootnote: true, footnoteText: t));
          }
          continue; // don't recurse — note content isn't scripture text
        case 'lb':
          segments.add(const VerseSegment(isLineBreak: true));
          plain.write(' ');
          continue;
        case 'w':
          walk(child,
              italic: italic,
              jesus: jesus,
              strongs: _extractStrongs(child.getAttribute('lemma')) ?? strongs);
          continue;
        case 'transChange':
          walk(child,
              italic: italic || child.getAttribute('type') == 'added',
              jesus: jesus,
              strongs: strongs);
          continue;
        case 'hi':
          final type = child.getAttribute('type');
          walk(child,
              italic: italic || type == 'italic' || type == 'emphasis',
              jesus: jesus,
              strongs: strongs);
          continue;
        case 'q':
          walk(child,
              italic: italic,
              jesus: jesus || child.getAttribute('who')?.toLowerCase() == 'jesus',
              strongs: strongs);
          continue;
        case 'title':
          // Canonical titles (e.g. Psalm superscriptions) are embedded in
          // verse 1 by many OSIS Bibles. Keep the text but break after it so
          // it neither merges into the following verse text ("David.The LORD")
          // nor pollutes search runs.
          walk(child, italic: italic, jesus: jesus, strongs: strongs);
          segments.add(const VerseSegment(isLineBreak: true));
          plain.write(' ');
          continue;
        default:
          // divineName, seg, foreign, title, rdg, …: flatten their text.
          walk(child, italic: italic, jesus: jesus, strongs: strongs);
      }
    }
  }

  XmlElement root;
  try {
    root = XmlDocument.parse('<osisFragment>$fragment</osisFragment>')
        .rootElement;
  } catch (_) {
    final stripped = fragment
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return ParsedOsisEntry(
        stripped, stripped.isEmpty ? const [] : [VerseSegment(text: stripped)]);
  }

  walk(root, italic: false, jesus: false, strongs: null);
  final text = plain.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  return ParsedOsisEntry(text, segments);
}

/// Pulls Strong's numbers out of an OSIS `lemma` attribute such as
/// `strong:H7225` or `strong:G2532 strong:G1161`, returning them space-joined
/// (e.g. `H7225`, `G2532 G1161`) or null when none are present.
String? _extractStrongs(String? lemma) {
  if (lemma == null) return null;
  final codes = RegExp(r'strong:([A-Za-z]?\d+)')
      .allMatches(lemma)
      .map((m) => m.group(1)!)
      .toList();
  return codes.isEmpty ? null : codes.join(' ');
}
