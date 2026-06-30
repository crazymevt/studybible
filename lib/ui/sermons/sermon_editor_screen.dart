import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/sermon_providers.dart';
import '../../app/revision_common.dart';
import '../../app/user_providers.dart';
import '../../data/export/sermon_exporter.dart';
import '../../data/logging.dart';
import '../../data/user_store.dart';
import 'export_dialog.dart';
import 'sermon_presentation_screen.dart';
import 'sermon_revisions_dialog.dart';
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

  /// `updatedAt` of the sermon version currently loaded in the editor. Lets the
  /// remote-change watcher tell the editor's own saves (which advance this)
  /// apart from a sync that overwrote the sermon underneath the open document.
  int _loadedUpdatedAt = 0;

  /// True while the editor itself is rewriting the sermon row (restore or
  /// accepting a remote version), so the watcher doesn't flag it as a conflict.
  bool _internalWrite = false;

  /// Set when a remote edit is detected while the editor is open. Autosave is
  /// paused and a banner is shown until the user picks a version.
  bool _conflictDetected = false;
  Sermon? _incomingRemote;

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
      _loadedUpdatedAt = sermon.updatedAt;

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

  String _currentContentJson() =>
      jsonEncode(_controller.document.toDelta().toJson());

  Future<void> _saveSermonContent() async {
    if (_conflictDetected || _internalWrite) return;
    final ts = await ref
        .read(sermonActionProvider)
        .updateSermon(widget.sermonId, content: _currentContentJson());
    _loadedUpdatedAt = ts;
  }

  Future<void> _saveSermonMetadata() async {
    if (_conflictDetected || _internalWrite) return;
    final ts = await ref.read(sermonActionProvider).updateSermon(
          widget.sermonId,
          title: _titleController.text,
          series: _seriesController.text.isNotEmpty ? _seriesController.text : null,
        );
    _loadedUpdatedAt = ts;
  }

  /// Swaps the supplied sermon's content/metadata into the live editor and
  /// resets the change marker. Callers must wrap this in `setState` (the editor
  /// widget reads the rebuilt `_controller`).
  void _applySermonToEditor(Sermon sermon) {
    _controller.removeListener(_saveSermonContent);
    _controller.dispose();

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
    _titleController.text = sermon.title;
    _seriesController.text = sermon.series ?? '';
    _loadedUpdatedAt = sermon.updatedAt;
  }

  /// Reacts to the sermon row changing underneath the open editor. The editor's
  /// own saves advance [_loadedUpdatedAt], so a newer row whose content/title
  /// differs from what's on screen can only be a remote (synced) edit.
  void _onSermonChanged(Sermon? sermon) {
    if (sermon == null || _internalWrite || _conflictDetected) return;
    if (sermon.deleted || sermon.updatedAt <= _loadedUpdatedAt) return;
    final changed = sermon.content != _currentContentJson() ||
        sermon.title != _titleController.text ||
        (sermon.series ?? '') != _seriesController.text;
    if (changed) {
      setState(() {
        _conflictDetected = true;
        _incomingRemote = sermon;
      });
    } else {
      // Our own write echoing back through the stream; just advance the marker.
      _loadedUpdatedAt = sermon.updatedAt;
    }
  }

  /// Keeps the open (local) version: preserves the incoming remote version as a
  /// revision, then re-saves the local content so it wins.
  Future<void> _keepMine() async {
    final remote = _incomingRemote;
    if (remote == null) return;
    _internalWrite = true;
    await ref.read(sermonRevisionActionProvider).saveRevision(
          sermonId: widget.sermonId,
          title: remote.title,
          series: remote.series,
          content: remote.content,
          label: 'Version from another device',
          kind: RevisionKind.conflict,
        );
    final ts = await ref.read(sermonActionProvider).updateSermon(
          widget.sermonId,
          title: _titleController.text,
          series:
              _seriesController.text.isNotEmpty ? _seriesController.text : null,
          content: _currentContentJson(),
        );
    _loadedUpdatedAt = ts;
    _internalWrite = false;
    if (mounted) {
      setState(() {
        _conflictDetected = false;
        _incomingRemote = null;
      });
    }
  }

  /// Accepts the incoming remote version: preserves the open local version as a
  /// revision, then loads the remote version into the editor.
  Future<void> _useTheirs() async {
    final remote = _incomingRemote;
    if (remote == null) return;
    _internalWrite = true;
    await ref.read(sermonRevisionActionProvider).saveRevision(
          sermonId: widget.sermonId,
          title: _titleController.text,
          series:
              _seriesController.text.isNotEmpty ? _seriesController.text : null,
          content: _currentContentJson(),
          label: 'Your version before reload',
          kind: RevisionKind.restore,
        );
    setState(() => _applySermonToEditor(remote));
    _internalWrite = false;
    if (mounted) {
      setState(() {
        _conflictDetected = false;
        _incomingRemote = null;
      });
    }
  }

  Future<void> _openRevisions() async {
    final restored = await SermonRevisionsDialog.show(
      context,
      sermonId: widget.sermonId,
      currentTitle: _titleController.text,
      currentSeries:
          _seriesController.text.isNotEmpty ? _seriesController.text : null,
      currentContent: _currentContentJson(),
    );
    if (restored == null || !mounted) return;

    _internalWrite = true;
    await ref.read(sermonRevisionActionProvider).restoreRevision(restored.id);
    final store = ref.read(userStoreProvider);
    final sermon = await (store.select(store.sermons)
          ..where((t) => t.id.equals(widget.sermonId)))
        .getSingleOrNull();
    if (sermon != null && mounted) {
      setState(() => _applySermonToEditor(sermon));
    }
    _internalWrite = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revision restored')),
      );
    }
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

    // Watch for a sync overwriting this sermon while the editor is open.
    ref.listen<AsyncValue<Sermon?>>(
      sermonByIdProvider(widget.sermonId),
      (prev, next) => _onSermonChanged(next.value),
    );

    final editorBody = LayoutBuilder(
      builder: (context, constraints) {
        // Let the toolbar wrap onto two rows when there's comfortably enough
        // vertical room for it plus the title fields and a usable editor, but
        // collapse to a single horizontally-scrolling row when space is tight
        // (e.g. the soft keyboard shrinks the panel) so the editor stays
        // visible instead of being squeezed out / overflowing.
        const titleFieldsHeight = 68.0;
        const twoRowToolbarHeight = 96.0;
        const minEditorHeight = 140.0;
        final bannerHeight = _conflictDetected ? 88.0 : 0.0;
        final multiRowToolbar = constraints.maxHeight >=
            bannerHeight +
                titleFieldsHeight +
                twoRowToolbarHeight +
                minEditorHeight;

        return Column(
          children: [
            if (_conflictDetected) _buildConflictBanner(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              config: QuillSimpleToolbarConfig(
                multiRowsDisplay: multiRowToolbar,
              ),
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
      },
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
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Revision History',
              onPressed: () => _openRevisions(),
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
                      icon: const Icon(Icons.history),
                      tooltip: 'Revision History',
                      onPressed: () => _openRevisions(),
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

  Widget _buildConflictBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: scheme.errorContainer,
      leading: Icon(Icons.sync_problem, color: scheme.onErrorContainer),
      content: Text(
        'This sermon was changed on another device while you had it open. '
        'Pick which version to keep — the other is saved to revision history '
        'either way.',
        style: TextStyle(color: scheme.onErrorContainer),
      ),
      actions: [
        TextButton(
          onPressed: _useTheirs,
          child: const Text('Use their version'),
        ),
        TextButton(
          onPressed: _keepMine,
          child: const Text('Keep mine'),
        ),
      ],
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
    final points = await showDialog<int>(
      context: context,
      builder: (_) => const _OutlinePointsDialog(),
    );
    if (points != null) _generateOutline(points);
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

/// Prompt for the number of outline points. A [StatefulWidget] so its
/// controller is disposed in [State.dispose] (after the route is gone) rather
/// than the instant `showDialog` returns, which races the dismiss animation and
/// throws "TextEditingController used after disposed". Pops with the chosen
/// point count, or null on cancel.
class _OutlinePointsDialog extends StatefulWidget {
  const _OutlinePointsDialog();

  @override
  State<_OutlinePointsDialog> createState() => _OutlinePointsDialogState();
}

class _OutlinePointsDialogState extends State<_OutlinePointsDialog> {
  final _pointsController = TextEditingController(text: '3');

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  void _submit() =>
      Navigator.pop(context, int.tryParse(_pointsController.text) ?? 3);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Outline'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How many points should the outline have?'),
          const SizedBox(height: 16),
          TextField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Number of Points'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
