import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/user_providers.dart';
import '../../app/app_state.dart';
import '../../app/reader_state.dart';
import '../../data/export/document_pdf.dart';
import '../tags/tag_editor_dialog.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

/// Heading shown for a note in the printed output and the panel list.
String _noteLabel(dynamic note) {
  if (note.selectedVerses != null) {
    return (note.selectedVerses as String).contains(',')
        ? 'Verses ${note.selectedVerses}'
        : 'Verse ${note.selectedVerses}';
  }
  if (note.verse != null) return 'Verse ${note.verse}';
  return 'Chapter Note';
}

class NotesPanel extends ConsumerWidget {
  const NotesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(chapterNotesProvider);
    final bookName = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final notes = notesAsync.value ?? const [];

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (notes.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.print),
                        tooltip: 'Print notes',
                        onPressed: () => printPlainTextDocument(
                          title: 'Notes — $bookName $chapter',
                          sections: [
                            for (final note in notes)
                              PdfDocSection(
                                heading: _noteLabel(note),
                                body: note.content,
                              ),
                          ],
                        ),
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
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const EmptyState(
                    icon: Icons.edit_note_outlined,
                    title: 'No notes yet',
                    message: 'Notes you write for this chapter appear here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final title = _noteLabel(note);

                    return ListTile(
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(note.content),
                      onTap: () {
                        if (note.selectedVerses != null) {
                          ref.read(selectedVersesProvider.notifier).clear();
                          final versesToSelect = note.selectedVerses!
                              .split(',')
                              .map((e) => int.tryParse(e.trim()) ?? 0)
                              .where((e) => e > 0);
                          for (final v in versesToSelect) {
                            ref.read(selectedVersesProvider.notifier).toggle(v);
                          }
                        } else if (note.verse != null) {
                          ref.read(selectedVersesProvider.notifier).clear();
                          ref
                              .read(selectedVersesProvider.notifier)
                              .toggle(note.verse!);
                        }
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete Note',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Note'),
                                  content: const Text('Are you sure you want to delete this note?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(noteActionProvider).deleteNote(note.id);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.label_outline),
                            tooltip: 'Manage Tags',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => TagEditorDialog(
                                  entityId: note.id,
                                  entityType: 'note',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const SkeletonList(),
              error: (err, stack) => const EmptyState(
                icon: Icons.error_outline,
                title: 'Couldn\'t load notes',
                message: 'Something went wrong. Pull up the panel again to retry.',
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
