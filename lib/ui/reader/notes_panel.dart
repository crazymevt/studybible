import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/user_providers.dart';
import '../../app/app_state.dart';
import '../../app/reader_state.dart';
import '../tags/tag_editor_dialog.dart';

class NotesPanel extends ConsumerWidget {
  const NotesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(chapterNotesProvider);

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
                IconButton(
                  icon: const Icon(Icons.close),
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
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('No notes for this chapter.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    String title;
                    if (note.selectedVerses != null) {
                      title = note.selectedVerses!.contains(',')
                          ? 'Verses ${note.selectedVerses}'
                          : 'Verse ${note.selectedVerses}';
                    } else if (note.verse != null) {
                      title = 'Verse ${note.verse}';
                    } else {
                      title = 'Chapter Note';
                    }

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
                      trailing: IconButton(
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
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
