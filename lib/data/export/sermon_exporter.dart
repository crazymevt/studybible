import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import '../user_store.dart';
import '../logging.dart';
import 'print_service.dart';
import 'document_pdf.dart';
import 'dart:io';

enum ExportFormat { pdf, html, text }
enum ExportAction { save, share, print }

class SermonExporter {
  static Future<void> exportSermons(BuildContext context, List<Sermon> sermons, ExportFormat format, ExportAction action) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Printing always produces a single combined PDF — the chosen export
      // format and the multi-sermon zip path don't apply to a print job.
      if (action == ExportAction.print) {
        final bytes = await _generatePdf(sermons);
        final name = sermons.length == 1 ? sermons.first.title : 'Sermons';
        await PrintService.printPdf(bytes, documentName: name);
        return;
      }

      Uint8List bytes;
      String filename;
      String mimeType;

      final isZip = sermons.length > 1;

      if (isZip) {
        bytes = await _generateZip(sermons, format);
        filename = 'Sermons.zip';
        mimeType = 'application/zip';
      } else {
        final sermon = sermons.first;
        switch (format) {
          case ExportFormat.pdf:
            bytes = await _generatePdf([sermon]);
            filename = '${sermon.title}.pdf';
            mimeType = 'application/pdf';
            break;
          case ExportFormat.html:
            bytes = await _generateHtml([sermon]);
            filename = '${sermon.title}.html';
            mimeType = 'text/html';
            break;
          case ExportFormat.text:
            bytes = await _generateText([sermon]);
            filename = '${sermon.title}.txt';
            mimeType = 'text/plain';
            break;
        }
      }

      if (action == ExportAction.save) {
        final saveLocation = await getSaveLocation(
          suggestedName: filename,
        );
        final String? path = saveLocation?.path;
        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(bytes);
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Saved to $path')),
          );
        }
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(bytes, name: filename, mimeType: mimeType)],
            text: 'Exported Sermons',
          ),
        );
      }
    } catch (e, stack) {
      logError(e, stack, context: 'SermonExporter.export');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to export: $e')),
      );
    }
  }

  static Future<Uint8List> _generateZip(List<Sermon> sermons, ExportFormat format) async {
    final archive = Archive();
    
    for (final sermon in sermons) {
      String ext;
      Uint8List fileBytes;
      
      switch (format) {
        case ExportFormat.pdf:
          fileBytes = await _generatePdf([sermon]);
          ext = '.pdf';
          break;
        case ExportFormat.html:
          fileBytes = await _generateHtml([sermon]);
          ext = '.html';
          break;
        case ExportFormat.text:
          fileBytes = await _generateText([sermon]);
          ext = '.txt';
          break;
      }
      
      final safeTitle = sermon.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      archive.addFile(ArchiveFile('$safeTitle$ext', fileBytes.length, fileBytes));
    }
    
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static Future<Uint8List> _generatePdf(List<Sermon> sermons) async {
    final pdf = pw.Document(theme: await loadPdfTheme());

    for (final sermon in sermons) {
      // Render the Quill delta with its formatting (headings, lists, bold…)
      // rather than flattening it to plain text; fall back to raw text if the
      // content can't be parsed.
      List<pw.Widget> body;
      try {
        body = quillDeltaToPdfWidgets(jsonDecode(sermon.content) as List<dynamic>);
      } catch (e, stack) {
        logError(e, stack, context: 'SermonExporter._generatePdf parse');
        body = [
          pw.Text(sermon.content,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
        ];
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          build: (pw.Context context) => [
            pw.Text(sermon.title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            if (sermon.series != null && sermon.series!.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(sermon.series!, style: pw.TextStyle(fontSize: 18, fontStyle: pw.FontStyle.italic)),
            ],
            pw.SizedBox(height: 20),
            ...body,
          ],
        ),
      );
    }

    return await pdf.save();
  }

  static Future<Uint8List> _generateHtml(List<Sermon> sermons) async {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head><meta charset="utf-8"><title>Sermons</title>');
    buffer.writeln('<style>body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; } .sermon { margin-bottom: 40px; } h1 { color: #333; } h2.series { color: #666; font-style: italic; font-size: 1.2em; }</style>');
    buffer.writeln('</head><body>');

    for (final sermon in sermons) {
      buffer.writeln('<div class="sermon">');
      buffer.writeln('<h1>${_escapeHtml(sermon.title)}</h1>');
      if (sermon.series != null && sermon.series!.isNotEmpty) {
        buffer.writeln('<h2 class="series">${_escapeHtml(sermon.series!)}</h2>');
      }
      
      try {
        final deltaJsonList = jsonDecode(sermon.content) as List<dynamic>;
        final converter = QuillDeltaToHtmlConverter(
          deltaJsonList.map((e) => e as Map<String, dynamic>).toList(),
        );
        buffer.writeln(converter.convert());
      } catch (e, stack) {
        logError(e, stack, context: 'SermonExporter._generateHtml parse');
        buffer.writeln('<p>${_escapeHtml(sermon.content)}</p>');
      }
      buffer.writeln('</div>');
      if (sermon != sermons.last) {
        buffer.writeln('<hr>');
      }
    }

    buffer.writeln('</body></html>');
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static Future<Uint8List> _generateText(List<Sermon> sermons) async {
    final buffer = StringBuffer();

    for (final sermon in sermons) {
      buffer.writeln(sermon.title);
      if (sermon.series != null && sermon.series!.isNotEmpty) {
        buffer.writeln('Series: ${sermon.series}');
      }
      buffer.writeln('---');
      try {
        final doc = Document.fromJson(jsonDecode(sermon.content));
        buffer.writeln(doc.toPlainText());
      } catch (e, stack) {
        logError(e, stack, context: 'SermonExporter._generateText parse');
        buffer.writeln(sermon.content);
      }
      
      if (sermon != sermons.last) {
        buffer.writeln('\n\n========================================\n\n');
      }
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
