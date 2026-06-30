import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pasteboard/pasteboard.dart';

/// A preview dialog that renders the selected verse(s) as a styled card over
/// the active theme's colors and lets the user share it as a PNG image — the
/// shareable format people actually post. The card is captured off the visible
/// [RepaintBoundary] so what they see is exactly what ships.
class VerseImageShareDialog extends StatefulWidget {
  /// e.g. "John 3:16 (ESV)".
  final String reference;

  /// The verse text, already cleaned and flowed into a single block.
  final String verseText;

  const VerseImageShareDialog({
    super.key,
    required this.reference,
    required this.verseText,
  });

  @override
  State<VerseImageShareDialog> createState() => _VerseImageShareDialogState();
}

class _VerseImageShareDialogState extends State<VerseImageShareDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _processImage({bool saveOnly = false, bool copyOnly = false}) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture at 3x for a crisp image on high-DPI screens.
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      if (saveOnly) {
        final saveLocation = await getSaveLocation(
          suggestedName: 'verse.png',
        );
        final result = saveLocation?.path;
        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(bytes, flush: true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image saved successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else if (copyOnly) {
        await Pasteboard.writeImage(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image copied to clipboard!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final origin = _shareOrigin();
        final path = await _writeTempPng(bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path, mimeType: 'image/png', name: 'verse.png')],
            subject: widget.reference,
            sharePositionOrigin: origin,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String> _writeTempPng(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final safeRef = widget.reference.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final file = File('${dir.path}/verse_$safeRef.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: VerseImageCard(
                  reference: widget.reference,
                  verseText: widget.verseText,
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => _processImage(copyOnly: true),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                    const SizedBox(width: 8),
                  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                    FilledButton.tonalIcon(
                      onPressed: _isProcessing ? null : () => _processImage(saveOnly: true),
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                    const SizedBox(width: 8),
                  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : () => _processImage(),
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ios_share),
                      label: const Text('Share'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The pure visual of the verse image: a themed gradient with the verse text
/// centered and the reference beneath. Reused as both the on-screen preview and
/// the captured bitmap, so they can never drift apart.
class VerseImageCard extends StatelessWidget {
  final String reference;
  final String verseText;

  const VerseImageCard({
    super.key,
    required this.reference,
    required this.verseText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onColor = scheme.onPrimaryContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '“$verseText”',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onColor,
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            reference,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onColor.withValues(alpha: 0.85),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
