import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/journal_providers.dart';
import 'journals_list_panel.dart';
import '../tags/tag_editor_dialog.dart';

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
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onDataChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final title = _titleController.text;
      final content = _contentController.text;

      if (title.isEmpty && content.isEmpty) return;

      final selectedDate = ref.read(selectedJournalDateProvider);

      final id = await ref
          .read(journalActionProvider)
          .saveJournal(_currentId, title, content, dateOverride: selectedDate);
      if (_currentId == null && mounted) {
        setState(() {
          _currentId = id;
        });
        // We do NOT update selectedJournalIdProvider here to avoid losing focus if it rebuilds too much,
        // but normally we'd want to set it so the list highlights it.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(selectedJournalIdProvider, (previous, next) {
      _currentId = next;
      _loadCurrentJournal();
    });

    return Column(
      children: [
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
                  icon: const Icon(Icons.delete, color: Colors.red),
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
                      final isDesktop = MediaQuery.sizeOf(this.context).width > 900;
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
