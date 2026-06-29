import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'print_service.dart';

pw.ThemeData? _cachedTheme;

/// A PDF theme backed by Noto Sans (regular/bold/italic) so non-ASCII glyphs —
/// the "•" bullet, and later Greek/Hebrew/Cyrillic Bible text — render. The
/// built-in PDF fonts are Latin-only and can't draw them. Fonts are fetched via
/// the printing package (cached after first use); returns null if the fetch
/// fails (e.g. offline), in which case the document falls back to the built-in
/// fonts rather than failing to print.
Future<pw.ThemeData?> loadPdfTheme() async {
  if (_cachedTheme != null) return _cachedTheme;
  try {
    _cachedTheme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
      italic: await PdfGoogleFonts.notoSansItalic(),
      boldItalic: await PdfGoogleFonts.notoSansBoldItalic(),
    );
    return _cachedTheme;
  } catch (_) {
    return null; // offline / fetch failed — retry on the next print
  }
}

/// One titled block in a plain-text PDF — e.g. a single note (heading = its
/// verse reference) or a journal entry (heading = title, subheading = date).
class PdfDocSection {
  final String heading;
  final String? subheading;
  final String body;
  const PdfDocSection({
    required this.heading,
    this.subheading,
    required this.body,
  });
}

/// Builds a simple, paginated plain-text PDF: a document [title] followed by
/// each section's heading / optional subheading / body. Used for notes and
/// journals, whose content is plain text.
Future<Uint8List> buildPlainTextPdf({
  required String title,
  required List<PdfDocSection> sections,
}) async {
  final pdf = pw.Document(theme: await loadPdfTheme());
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      build: (context) => [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Divider(),
        pw.SizedBox(height: 8),
        for (final s in sections) ...[
          pw.Text(
            s.heading,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          if (s.subheading != null && s.subheading!.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              s.subheading!,
              style: pw.TextStyle(
                fontSize: 11,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            s.body,
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.4),
          ),
          pw.SizedBox(height: 16),
        ],
      ],
    ),
  );
  return pdf.save();
}

/// Builds a plain-text PDF and opens the system print sheet.
Future<void> printPlainTextDocument({
  required String title,
  required List<PdfDocSection> sections,
}) async {
  final bytes = await buildPlainTextPdf(title: title, sections: sections);
  await PrintService.printPdf(bytes, documentName: title);
}

// ---------------------------------------------------------------------------
// Quill delta -> pdf widgets (for sermons, the one rich-text content type).
// ---------------------------------------------------------------------------

class _InlineSpan {
  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  const _InlineSpan(this.text,
      {this.bold = false, this.italic = false, this.underline = false});
}

/// Converts a Quill delta (a list of `{insert, attributes}` op maps) into PDF
/// widgets, preserving headings, bullet/ordered lists, blockquotes and inline
/// bold/italic/underline. Unknown attributes (colour, embeds, alignment) are
/// ignored — the goal is a clean, readable layout, not pixel fidelity. Replaces
/// flattening the document to plain text for the sermon PDF.
List<pw.Widget> quillDeltaToPdfWidgets(List<dynamic> ops) {
  final widgets = <pw.Widget>[];
  var line = <_InlineSpan>[];
  var orderedCounter = 0;

  String plain(List<_InlineSpan> spans) => spans.map((s) => s.text).join();

  pw.TextSpan inline(List<_InlineSpan> spans, {double fontSize = 12}) {
    return pw.TextSpan(
      children: [
        for (final s in spans)
          pw.TextSpan(
            text: s.text,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: s.bold ? pw.FontWeight.bold : null,
              fontStyle: s.italic ? pw.FontStyle.italic : null,
              decoration: s.underline ? pw.TextDecoration.underline : null,
            ),
          ),
      ],
    );
  }

  void flush(Map<String, dynamic> blockAttrs) {
    final header = blockAttrs['header'];
    final list = blockAttrs['list'];
    final isQuote = blockAttrs['blockquote'] == true;

    // Track ordered-list numbering across consecutive items.
    if (list == 'ordered') {
      orderedCounter++;
    } else {
      orderedCounter = 0;
    }

    if (line.isEmpty && header == null && list == null && !isQuote) {
      widgets.add(pw.SizedBox(height: 8));
      return;
    }

    pw.Widget content;
    if (header == 1 || header == 2 || header == 3) {
      final size = header == 1 ? 22.0 : (header == 2 ? 18.0 : 15.0);
      content = pw.Text(
        plain(line),
        style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
      );
    } else if (list == 'bullet' || list == 'ordered') {
      final marker = list == 'ordered' ? '$orderedCounter.' : '•';
      content = pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 22,
            child: pw.Text(marker,
                style: const pw.TextStyle(fontSize: 12)),
          ),
          pw.Expanded(child: pw.RichText(text: inline(line))),
        ],
      );
    } else if (isQuote) {
      content = pw.Container(
        padding: const pw.EdgeInsets.only(left: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: PdfColors.grey400, width: 3),
          ),
        ),
        child: pw.RichText(
          text: inline(
            line.map((s) => _InlineSpan(s.text,
                bold: s.bold, italic: true, underline: s.underline)).toList(),
          ),
        ),
      );
    } else {
      content = pw.RichText(text: inline(line));
    }

    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: content,
      ),
    );
  }

  for (final op in ops) {
    if (op is! Map) continue;
    final insert = op['insert'];
    final attrs =
        (op['attributes'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (insert is! String) continue; // skip embeds (images, etc.)

    final parts = insert.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        line.add(_InlineSpan(
          parts[i],
          bold: attrs['bold'] == true,
          italic: attrs['italic'] == true,
          underline: attrs['underline'] == true,
        ));
      }
      // Every part except the last was terminated by a newline, whose op
      // attributes carry the block-level formatting for that line.
      if (i < parts.length - 1) {
        flush(attrs);
        line = <_InlineSpan>[];
      }
    }
  }
  if (line.isNotEmpty) flush(const {});

  return widgets;
}
