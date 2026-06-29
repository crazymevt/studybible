import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/sermon_providers.dart';
import '../../app/user_providers.dart';
import '../../data/export/sermon_exporter.dart';
import '../../data/logging.dart';
import 'export_dialog.dart';
import 'sermon_presentation_screen.dart';
import '../tags/tag_editor_dialog.dart';


class SermonEditorScreen extends ConsumerStatefulWidget {
  final String sermonId;
  final bool isFullScreen;

  const SermonEditorScreen({super.key, required this.sermonId, this.isFullScreen = true});

  @override
  ConsumerState<SermonEditorScreen> createState() => _SermonEditorScreenState();
}

class _SermonEditorScreenState extends ConsumerState<SermonEditorScreen> {
  late QuillController _controller;
  bool _isInitialized = false;
  final _titleController = TextEditingController();
  final _seriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSermon();
  }

  Future<void> _loadSermon() async {
    final store = ref.read(userStoreProvider);
    final sermon = await (store.select(store.sermons)..where((t) => t.id.equals(widget.sermonId))).getSingleOrNull();
    if (sermon != null) {
      _titleController.text = sermon.title;
      _seriesController.text = sermon.series ?? '';
      
      List<dynamic> jsonData;
      try {
        jsonData = jsonDecode(sermon.content);
      } catch (e, stack) {
        logError(e, stack, context: 'SermonEditor: parse content');
        jsonData = [{'insert': '\\n'}];
      }
      
      _controller = QuillController(
        document: Document.fromJson(jsonData),
        selection: const TextSelection.collapsed(offset: 0),
      );
      
      _controller.addListener(_saveSermonContent);
      _titleController.addListener(_saveSermonMetadata);
      _seriesController.addListener(_saveSermonMetadata);
      
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _saveSermonContent() {
    final content = jsonEncode(_controller.document.toDelta().toJson());
    ref.read(sermonActionProvider).updateSermon(widget.sermonId, content: content);
  }

  void _saveSermonMetadata() {
    ref.read(sermonActionProvider).updateSermon(
      widget.sermonId,
      title: _titleController.text,
      series: _seriesController.text.isNotEmpty ? _seriesController.text : null,
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.removeListener(_saveSermonContent);
      _controller.dispose();
      _titleController.dispose();
      _seriesController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      if (widget.isFullScreen) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }

    final editorBody = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _seriesController,
                  decoration: const InputDecoration(labelText: 'Series'),
                ),
              ),
            ],
          ),
        ),
        QuillSimpleToolbar(
          controller: _controller,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QuillEditor.basic(
                controller: _controller,
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.isFullScreen) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          title: const Text('Edit Sermon'),
          actions: [
            IconButton(
              icon: const Icon(Icons.slideshow),
              tooltip: 'Presentation Mode',
              onPressed: () {
                final store = ref.read(userStoreProvider);
                store.select(store.sermons)
                  ..where((t) => t.id.equals(widget.sermonId))
                  ..getSingleOrNull().then((sermon) {
                    if (sermon != null && context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SermonPresentationScreen(sermon: sermon),
                      ));
                    }
                  });
              },
            ),
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: 'Export',
              onPressed: () {
                final store = ref.read(userStoreProvider);
                store.select(store.sermons)
                  ..where((t) => t.id.equals(widget.sermonId))
                  ..getSingleOrNull().then((sermon) {
                    if (sermon != null && context.mounted) {
                      ExportDialog.show(context, [sermon]);
                    }
                  });
              },
            ),
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print',
              onPressed: () => _printSermon(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.label),
              tooltip: 'Manage Tags',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => TagEditorDialog(
                    entityId: widget.sermonId,
                    entityType: 'sermon',
                  ),
                );
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.list_alt),
              label: const Text('Outline'),
              onPressed: () => _showOutlineGeneratorDialog(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: editorBody,
      );
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        ref.read(selectedSermonIdProvider.notifier).set(null);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Sermon',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.slideshow),
                      tooltip: 'Presentation Mode',
                      onPressed: () {
                        final store = ref.read(userStoreProvider);
                        store.select(store.sermons)
                          ..where((t) => t.id.equals(widget.sermonId))
                          ..getSingleOrNull().then((sermon) {
                            if (sermon != null && context.mounted) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => SermonPresentationScreen(sermon: sermon),
                              ));
                            }
                          });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_upload),
                      tooltip: 'Export',
                      onPressed: () {
                        final store = ref.read(userStoreProvider);
                        store.select(store.sermons)
                          ..where((t) => t.id.equals(widget.sermonId))
                          ..getSingleOrNull().then((sermon) {
                            if (sermon != null && context.mounted) {
                              ExportDialog.show(context, [sermon]);
                            }
                          });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      tooltip: 'Print',
                      onPressed: () => _printSermon(context, ref),
                    ),
                    IconButton(
                      icon: const Icon(Icons.label),
                      tooltip: 'Manage Tags',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => TagEditorDialog(
                            entityId: widget.sermonId,
                            entityType: 'sermon',
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.list_alt),
                      tooltip: 'Outline',
                      onPressed: () => _showOutlineGeneratorDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      tooltip: 'Full Screen',
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => SermonEditorScreen(sermonId: widget.sermonId, isFullScreen: true),
                        ));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: editorBody),
        ],
      ),
    );
  }

  void _printSermon(BuildContext context, WidgetRef ref) {
    final store = ref.read(userStoreProvider);
    store.select(store.sermons)
      ..where((t) => t.id.equals(widget.sermonId))
      ..getSingleOrNull().then((sermon) {
        if (sermon != null && context.mounted) {
          // Printing always produces a PDF, so we skip the export dialog's
          // format selection entirely.
          SermonExporter.exportSermons(
            context,
            [sermon],
            ExportFormat.pdf,
            ExportAction.print,
          );
        }
      });
  }

  Future<void> _showOutlineGeneratorDialog(BuildContext context) async {
    final pointsController = TextEditingController(text: '3');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Outline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many points should the outline have?'),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Points'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final points = int.tryParse(pointsController.text) ?? 3;
              _generateOutline(points);
              Navigator.pop(context);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    pointsController.dispose();
  }

  void _generateOutline(int numPoints) {
    final currentLength = _controller.document.length;
    int index = currentLength > 1 ? currentLength - 1 : 0;
    
    final delta = Delta()
      ..retain(index)
      ..insert('\n')
      ..insert('Introduction')
      ..insert('\n', {'header': 2})
      ..insert('\n');
      
    for (int i = 1; i <= numPoints; i++) {
      delta
        ..insert('Point $i: ', {'bold': true})
        ..insert('\n', {'header': 3})
        ..insert('Reference: ')
        ..insert('\n', {'list': 'bullet'})
        ..insert('Application: ')
        ..insert('\n', {'list': 'bullet'})
        ..insert('\n');
    }
    
    delta
      ..insert('Conclusion')
      ..insert('\n', {'header': 2})
      ..insert('\n');

    // Compose through the controller (not _controller.document) so its change
    // listeners fire — _saveSermonContent is one of them. Editing the document
    // directly updates the on-screen editor but skips that notification, so a
    // generated outline was never persisted unless the user also typed
    // something afterward (which does go through the controller).
    _controller.compose(delta, _controller.selection, ChangeSource.local);
  }
}
