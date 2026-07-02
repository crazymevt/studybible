import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/scratch_providers.dart';
import '../../app/user_providers.dart';
import '../common/quill_content.dart';
import '../common/reference_autolink.dart';

/// The Scratch space: a single, device-local rich-text pad for rough notes that
/// never sync. Autosaves as you type and can be promoted into a full sermon.
class ScratchPanel extends ConsumerStatefulWidget {
  const ScratchPanel({super.key});

  @override
  ConsumerState<ScratchPanel> createState() => _ScratchPanelState();
}

class _ScratchPanelState extends ConsumerState<ScratchPanel> {
  QuillController? _controller;
  StreamSubscription<DocChange>? _docSub;
  Timer? _debounce;

  // True while we rewrite the pad ourselves (clear), so the resulting document
  // change doesn't re-schedule a save.
  bool _internalWrite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(userStoreProvider);
    final row = await (store.select(store.scratches)
          ..where((s) => s.id.equals(kScratchPadId)))
        .getSingleOrNull();
    _setDocument(documentFromStoredContent(row?.content ?? ''));
    if (mounted) setState(() {});
  }

  void _setDocument(Document doc) {
    _docSub?.cancel();
    _controller?.dispose();
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    // Listen to document changes (real edits), not the controller (which also
    // fires on cursor moves), so merely opening the pad doesn't schedule a save.
    _docSub = doc.changes.listen((event) {
      if (event.source == ChangeSource.local) _onChanged();
    });
    _controller = controller;
  }

  void _onChanged() {
    if (_internalWrite) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final controller = _controller;
      if (controller == null) return;
      // Turn any newly-typed Bible references into reader links before saving.
      // Idempotent, so the document-change echo it triggers settles after one
      // no-op pass rather than looping.
      applyReferenceAutolinks(controller, autolinkBooks(ref));
      final content = jsonEncode(controller.document.toDelta().toJson());
      ref.read(scratchActionProvider).save(content);
    });
  }

  @override
  void dispose() {
    _docSub?.cancel();
    _controller?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool _isEmpty() =>
      (_controller?.document.toPlainText() ?? '').trim().isEmpty;

  Future<void> _clear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear scratch pad'),
        content: const Text('Erase everything on the scratch pad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _internalWrite = true;
    setState(() => _setDocument(Document()));
    await ref.read(scratchActionProvider).clear();
    _internalWrite = false;
  }

  Future<void> _promote() async {
    final controller = _controller;
    if (controller == null || _isEmpty()) return;

    // Default the sermon title to the pad's first non-empty line.
    final firstLine = controller.document
        .toPlainText()
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    final titleController = TextEditingController(text: firstLine);

    final title = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Promote to sermon'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Sermon title'),
          onSubmitted: (v) => Navigator.pop(c, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, titleController.text.trim()),
            child: const Text('Create sermon'),
          ),
        ],
      ),
    );
    titleController.dispose();
    if (title == null || !mounted) return;

    final content = jsonEncode(controller.document.toDelta().toJson());
    await ref.read(scratchActionProvider).promoteToSermon(
          title.isEmpty ? 'Untitled sermon' : title,
          content,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Promoted to sermon — find it in the Sermons panel. '
          'The scratch pad is unchanged.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller;

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Text(
                  'Scratch',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.co_present),
                  tooltip: 'Promote to sermon',
                  onPressed: _promote,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear scratch pad',
                  onPressed: _clear,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () {
                    ref.read(activeToolProvider.notifier).close();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: controller == null
                ? const SizedBox.shrink()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Wrap the toolbar onto multiple rows when there's room,
                      // else a single scrolling row so it doesn't crowd the pad.
                      const minEditorHeight = 160.0;
                      const multiRowToolbarHeight = 150.0;
                      final multiRow = constraints.maxHeight >=
                          minEditorHeight + multiRowToolbarHeight;
                      return Column(
                        children: [
                          QuillSimpleToolbar(
                            controller: controller,
                            config: QuillSimpleToolbarConfig(
                              multiRowsDisplay: multiRow,
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: QuillEditor.basic(
                                controller: controller,
                                config: QuillEditorConfig(
                                  placeholder:
                                      'Jot rough notes here. They stay on this '
                                      'device and never sync. Promote to a sermon '
                                      'when an idea is ready.',
                                  customLinkPrefixes: referenceLinkPrefixes,
                                  customRecognizerBuilder:
                                      referenceRecognizerBuilder(ref, context),
                                  onLaunchUrl: (url) =>
                                      handleReferenceLaunch(ref, context, url),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
