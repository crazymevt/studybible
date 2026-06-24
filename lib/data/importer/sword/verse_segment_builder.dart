import '../../models/verse_segment.dart';
import 'parsed_verse_entry.dart';

/// Accumulates [VerseSegment]s and the parallel plain text while a per-source
/// fragment parser walks its markup.
///
/// Shared by the GBF and ThML filters, which (unlike OSIS) place Strong's codes
/// *after* the word they annotate — see [attachStrongs]. Footnotes are captured
/// as segments and deliberately kept out of the plain (searchable) text.
class VerseSegmentBuilder {
  final List<VerseSegment> _segments = [];
  final StringBuffer _plain = StringBuffer();

  /// Append running scripture text under the given styling.
  void addText(String raw, {bool italic = false, bool jesus = false}) {
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return;
    _segments.add(
      VerseSegment(text: collapsed, isItalic: italic, isJesusWords: jesus),
    );
    _plain.write(collapsed);
  }

  /// Record a footnote/cross-ref, kept out of the plain text.
  void addFootnote(String raw) {
    final t = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isNotEmpty) {
      _segments.add(VerseSegment(isFootnote: true, footnoteText: t));
    }
  }

  void addLineBreak() {
    _segments.add(const VerseSegment(isLineBreak: true));
    _plain.write(' ');
  }

  void addParagraphBreak() {
    _segments.add(const VerseSegment(isParagraphBreak: true));
    _plain.write(' ');
  }

  /// Attach a Strong's [code] to the last word of the most recent text segment,
  /// splitting that word into its own segment. GBF/ThML emit the code *after*
  /// the word, so the most recently added text holds the word to annotate.
  void attachStrongs(String code) {
    final i = _segments.lastIndexWhere(
        (s) => !s.isFootnote && !s.isLineBreak && !s.isParagraphBreak);
    if (i < 0) return;
    final seg = _segments[i];
    // Already a single-word Strong's segment (e.g. two codes on one word) —
    // merge the codes rather than splitting again.
    if (seg.strongs != null) {
      _segments[i] = VerseSegment(
        text: seg.text,
        isItalic: seg.isItalic,
        isJesusWords: seg.isJesusWords,
        strongs: '${seg.strongs} $code',
      );
      return;
    }
    final m = RegExp(r'^(.*?)(\S+)(\s*)$', dotAll: true).firstMatch(seg.text);
    if (m == null) return;
    final head = m.group(1)!;
    final word = m.group(2)! + m.group(3)!;
    _segments.replaceRange(i, i + 1, [
      if (head.isNotEmpty)
        VerseSegment(
            text: head, isItalic: seg.isItalic, isJesusWords: seg.isJesusWords),
      VerseSegment(
        text: word,
        isItalic: seg.isItalic,
        isJesusWords: seg.isJesusWords,
        strongs: code,
      ),
    ]);
  }

  ParsedVerseEntry build() {
    final text = _plain.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return ParsedVerseEntry(text, _segments);
  }
}
