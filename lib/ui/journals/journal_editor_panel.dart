import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/journal_providers.dart';
import '../../app/revision_common.dart';
import '../../app/user_providers.dart';
import '../../data/export/document_pdf.dart';
import '../../data/user_store.dart';
import 'journal_revisions_dialog.dart';
import 'journals_list_panel.dart';
import '../tags/tag_editor_dialog.dart';
import '../common/breakpoints.dart';

class JournalEditorPanel extends ConsumerStatefulWidget {
  const JournalEditorPanel({super.key});

  @override
  ConsumerState<JournalEditorPanel> createState() => _JournalEditorPanelState();
}

class _JournalEditorPanelState extends ConsumerState<JournalEditorPanel> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Timer? _debounce;
  String? _currentId;

  /// What the editor last persisted/loaded for [_currentId]. A watched row that
  /// differs from this came from elsewhere (a sync). Journals can't use a
  /// timestamp signal like sermons do — their updatedAt is the entry's date and
  /// doesn't advance on edits — so conflict detection is content-based.
  String _lastSavedTitle = '';
  String _lastSavedContent = '';

  /// True while the editor itself rewrites the journal row (restore / accept
  /// remote), so the watcher doesn't flag it as a conflict.
  bool _internalWrite = false;

  /// Set when a remote edit lands underneath the open editor. Autosave pauses
  /// and a banner is shown until the user picks a version.
  bool _conflictDetected = false;
  Journal? _incomingRemote;

  @override
  void initState() {
    super.initState();
    _currentId = ref.read(selectedJournalIdProvider);
    _loadCurrentJournal();
  }

  void _loadCurrentJournal() {
    if (_currentId == null) {
      _titleController.clear();
      _contentController.clear();
      _lastSavedTitle = '';
      _lastSavedContent = '';
    } else {
      final journals = ref.read(journalsProvider).value ?? [];
      final journal = journals.where((j) => j.id == _currentId).firstOrNull;
      if (journal != null) {
        if (_titleController.text != journal.title) {
          _titleController.text = journal.title;
        }
        if (_contentController.text != journal.content) {
          _contentController.text = journal.content;
        }
        _lastSavedTitle = journal.title;
        _lastSavedContent = journal.content;
      }
    }
    _conflictDetected = false;
    _incomingRemote = null;
  }

  /// Loads [j]'s content/title into the editor and resets the change baseline.
  void _applyJournal(Journal j) {
    _titleController.text = j.title;
    _contentController.text = j.content;
    _lastSavedTitle = j.title;
    _lastSavedContent = j.content;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onDataChanged() {
    if (_conflictDetected || _internalWrite) return; // paused / our own write
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (_conflictDetected || _internalWrite) return;
      final title = _titleController.text;
      final content = _contentController.text;

      if (title.isEmpty && content.isEmpty) return;

      final selectedDate = ref.read(selectedJournalDateProvider);

      // Record what we're about to persist before the write, so the row's own
      // stream echo isn't mistaken for a remote edit (even if the user keeps
      // typing before the echo arrives).
      _lastSavedTitle = title;
      _lastSavedContent = content;

      final id = await ref
          .read(journalActionProvider)
          .saveJournal(_currentId, title, content, dateOverride: selectedDate);
      if (_currentId == null && mounted) {
        setState(() {
          _currentId = id;
        });
        ref.read(selectedJournalIdProvider.notifier).setId(id);
      }
    });
  }

  /// Reacts to the journal row changing underneath the open editor.
  void _onJournalChanged(Journal? j) {
    if (j == null || _internalWrite || _conflictDetected) return;
    if (_currentId == null || j.id != _currentId || j.deleted) return;
    final externallyChanged =
        j.content != _lastSavedContent || j.title != _lastSavedTitle;
    if (!externallyChanged) return;
    final differsFromScreen =
        j.content != _contentController.text || j.title != _titleController.text;
    if (differsFromScreen) {
      setState(() {
        _conflictDetected = true;
        _incomingRemote = j;
      });
    } else {
      // Our own write echoing back; just advance the baseline.
      _lastSavedTitle = j.title;
      _lastSavedContent = j.content;
    }
  }

  /// Keeps the open (local) version: preserves the incoming remote version as a
  /// revision, then re-saves the local content so it wins. The save is stamped
  /// one ms past the remote's timestamp so it wins LWW while staying on the
  /// same calendar day (the remote stamp is that day's midnight).
  Future<void> _keepMine() async {
    final remote = _incomingRemote;
    final id = _currentId;
    if (remote == null || id == null) return;
    _internalWrite = true;
    await ref.read(journalRevisionActionProvider).saveRevision(
          journalId: id,
          title: remote.title,
          content: remote.content,
          tags: remote.tags,
          label: 'Version from another device',
          kind: RevisionKind.conflict,
        );
    final title = _titleController.text;
    final content = _contentController.text;
    await ref.read(journalActionProvider).saveJournal(
          id,
          title,
          content,
          dateOverride:
              DateTime.fromMillisecondsSinceEpoch(remote.updatedAt + 1),
        );
    _lastSavedTitle = title;
    _lastSavedContent = content;
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
    final id = _currentId;
    if (remote == null || id == null) return;
    _internalWrite = true;
    await ref.read(journalRevisionActionProvider).saveRevision(
          journalId: id,
          title: _titleController.text,
          content: _contentController.text,
          label: 'Your version before reload',
          kind: RevisionKind.restore,
        );
    setState(() => _applyJournal(remote));
    _internalWrite = false;
    if (mounted) {
      setState(() {
        _conflictDetected = false;
        _incomingRemote = null;
      });
    }
  }

  Future<void> _openRevisions() async {
    final id = _currentId;
    if (id == null) return;
    final restored = await JournalRevisionsDialog.show(
      context,
      journalId: id,
      currentTitle: _titleController.text,
      currentContent: _contentController.text,
    );
    if (restored == null || !mounted) return;

    _internalWrite = true;
    await ref.read(journalRevisionActionProvider).restoreRevision(restored.id);
    final store = ref.read(userStoreProvider);
    final journal = await (store.select(store.journals)
          ..where((j) => j.id.equals(id)))
        .getSingleOrNull();
    if (journal != null && mounted) {
      setState(() => _applyJournal(journal));
    }
    _internalWrite = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revision restored')),
      );
    }
  }

  Widget _buildConflictBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: scheme.errorContainer,
      leading: Icon(Icons.sync_problem, color: scheme.onErrorContainer),
      content: Text(
        'This entry was changed on another device while you had it open. '
        'Pick which version to keep — the other is saved to revision history '
        'either way.',
        style: TextStyle(color: scheme.onErrorContainer),
      ),
      actions: [
        TextButton(onPressed: _useTheirs, child: const Text('Use their version')),
        TextButton(onPressed: _keepMine, child: const Text('Keep mine')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(selectedJournalIdProvider, (previous, next) {
      if (_currentId != next) {
        setState(() {
          _currentId = next;
        });
        _loadCurrentJournal();
      }
    });

    ref.listen<DateTime>(selectedJournalDateProvider, (previous, next) {
      if (previous != next) {
        final targetId = ref.read(selectedJournalIdProvider);
        if (targetId == null) {
          setState(() {
            _currentId = null;
          });
          _loadCurrentJournal();
        }
      }
    });

    // Watch for a sync overwriting this entry while the editor is open.
    if (_currentId != null) {
      ref.listen<AsyncValue<Journal?>>(
        journalByIdProvider(_currentId!),
        (prev, next) => _onJournalChanged(next.value),
      );
    }

    return Column(
      children: [
        if (_conflictDetected) _buildConflictBanner(context),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  onChanged: (_) => _onDataChanged(),
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    hintText: 'Journal Title',
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_currentId != null) ...[
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'Revision History',
                    onPressed: _openRevisions,
                  ),
                  IconButton(
                    icon: const Icon(Icons.print),
                    tooltip: 'Print',
                    onPressed: () {
                      final title = _titleController.text.trim().isEmpty
                          ? 'Journal Entry'
                          : _titleController.text.trim();
                      final date = ref.read(selectedJournalDateProvider);
                      printPlainTextDocument(
                        title: title,
                        sections: [
                          PdfDocSection(
                            heading: title,
                            subheading:
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                            body: _contentController.text,
                          ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.label),
                    tooltip: 'Manage Tags',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => TagEditorDialog(
                          entityId: _currentId!,
                          entityType: 'journal',
                        ),
                      );
                    },
                  ),
                  IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete Journal',
                  onPressed: () async {
                    final targetId = _currentId;
                    if (targetId == null) return;
                    
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete Journal'),
                        content: const Text(
                          'Are you sure you want to delete this entry?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(journalActionProvider)
                          .deleteJournal(targetId);
                      ref.read(selectedJournalIdProvider.notifier).setId(null);
                      if (!mounted) return;
                      final isDesktop = MediaQuery.sizeOf(this.context).width > Breakpoints.compact;
                      if (!isDesktop) {
                        Navigator.of(this.context).pop();
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _contentController,
              onChanged: (_) => _onDataChanged(),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Write your thoughts here... (Supports Markdown)',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
