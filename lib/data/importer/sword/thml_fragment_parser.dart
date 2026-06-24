import 'package:xml/xml.dart';

import 'parsed_verse_entry.dart';
import 'verse_segment_builder.dart';

/// Parses a single verse's **ThML** (Theological Markup Language) fragment into
/// plain text plus segments, mirroring what `parseOsisFragment` does for OSIS.
///
/// ThML is XML, so the fragment is wrapped and parsed as a tree. The elements
/// handled here:
///
/// * `<note>` — a footnote; captured as a segment and kept out of plain text.
/// * `<sync type="Strongs" value="G1234"/>` — a Strong's number. Like GBF,
///   ThML places the `sync` *after* the word it annotates, so it is attached to
///   the preceding word. Non-Strongs `sync`s (e.g. `type="morph"`) are ignored.
/// * `<i>`/`<em>` — italic/added words; `<br/>` — line break; `<p>`/`<div>` —
///   paragraph break around their content.
///
/// Any other element flattens to its text. If the fragment is not well-formed
/// XML, the parser falls back to crude tag-stripping so the verse is still
/// captured as plain text.
ParsedVerseEntry parseThmlFragment(String fragment) {
  final b = VerseSegmentBuilder();

  void walk(XmlNode node, {required bool italic, required bool jesus}) {
    for (final child in node.children) {
      if (child is XmlText) {
        b.addText(child.value, italic: italic, jesus: jesus);
        continue;
      }
      if (child is! XmlElement) continue;

      switch (child.localName.toLowerCase()) {
        case 'note':
          // Footnotes/cross-refs: capture as a segment, never as verse text.
          b.addFootnote(child.innerText);
          continue; // don't recurse — note content isn't scripture text
        case 'sync':
          final type = child.getAttribute('type')?.toLowerCase();
          if (type == 'strongs') {
            final v = child.getAttribute('value')?.trim();
            if (v != null && v.isNotEmpty) b.attachStrongs(v);
          }
          continue; // self-closing marker
        case 'br':
          b.addLineBreak();
          continue;
        case 'p':
        case 'div':
          walk(child, italic: italic, jesus: jesus);
          b.addParagraphBreak();
          continue;
        case 'i':
        case 'em':
          walk(child, italic: true, jesus: jesus);
          continue;
        default:
          // b, font, span, scripRef, term, …: flatten their text.
          walk(child, italic: italic, jesus: jesus);
      }
    }
  }

  XmlElement root;
  try {
    root = XmlDocument.parse('<thmlFragment>$fragment</thmlFragment>')
        .rootElement;
  } catch (_) {
    final stripped = fragment
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (stripped.isNotEmpty) b.addText(stripped);
    return b.build();
  }

  walk(root, italic: false, jesus: false);
  return b.build();
}
