import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/scripture_nav_providers.dart';
import '../../data/user_store.dart';
import '../../data/logging.dart';
import '../common/reference_autolink.dart';

class SermonPresentationScreen extends ConsumerStatefulWidget {
  final Sermon sermon;

  const SermonPresentationScreen({super.key, required this.sermon});

  @override
  ConsumerState<SermonPresentationScreen> createState() => _SermonPresentationScreenState();
}

class _SermonPresentationScreenState extends ConsumerState<SermonPresentationScreen> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    Document document;
    try {
      final decoded = jsonDecode(widget.sermon.content);
      document = Document.fromJson(decoded);
    } catch (e, stack) {
      logError(e, stack, context: 'SermonPresentation: parse content');
      document = Document()..insert(0, widget.sermon.content);
    }
    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds the scripture route from the presented document's references and
  /// starts navigation mode, returning to the reader.
  void _startScriptureNavigation() {
    final stops = scanSermonRoute(
      _controller.document.toPlainText(),
      autolinkBooks(ref),
    );
    if (stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No scripture references found in this sermon.'),
        ),
      );
      return;
    }
    final title =
        widget.sermon.title.isEmpty ? 'Untitled Sermon' : widget.sermon.title;
    ref
        .read(scriptureNavProvider.notifier)
        .start(sermonTitle: title, stops: stops);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.sermon.title),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.route_outlined),
            tooltip: 'Navigate Scriptures',
            onPressed: _startScriptureNavigation,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
              ),
              child: QuillEditor.basic(
                controller: _controller,
                config: QuillEditorConfig(
                  customLinkPrefixes: referenceLinkPrefixes,
                  customRecognizerBuilder:
                      referenceRecognizerBuilder(ref, context),
                  onLaunchUrl: (url) =>
                      handleReferenceLaunch(ref, context, url),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
