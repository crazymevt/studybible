import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../data/user_store.dart';

class SermonPresentationScreen extends StatefulWidget {
  final Sermon sermon;

  const SermonPresentationScreen({super.key, required this.sermon});

  @override
  State<SermonPresentationScreen> createState() => _SermonPresentationScreenState();
}

class _SermonPresentationScreenState extends State<SermonPresentationScreen> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    Document document;
    try {
      final decoded = jsonDecode(widget.sermon.content);
      document = Document.fromJson(decoded);
    } catch (e) {
      debugPrint('Failed to parse sermon content as Quill document: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.sermon.title),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
