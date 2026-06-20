import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/user_providers.dart';

import '../../app/app_state.dart';

class StudyPane extends ConsumerWidget {
  const StudyPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(chapterNotesProvider);
    final bookmarksAsync = ref.watch(chapterBookmarksProvider);

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
                Text(
                  'Library',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (MediaQuery.sizeOf(context).width > 800) {
                      ref.read(activeToolProvider.notifier).close();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
              child: ListView(
                children: [
                  _SectionHeader(title: 'Notes'),
                  notesAsync.when(
                    data: (notes) {
                      if (notes.isEmpty)
                        return const _EmptyItem(
                          text: 'No notes for this chapter.',
                        );
                      return Column(
                        children: notes
                            .map(
                              (n) => ListTile(
                                title: Text(
                                  n.verse != null
                                      ? 'Verse ${n.verse}'
                                      : 'Chapter Note',
                                ),
                                subtitle: Text(
                                  n.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () => ref
                                      .read(noteActionProvider)
                                      .deleteNote(n.id),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                  const Divider(),
                  _SectionHeader(title: 'Bookmarks'),
                  bookmarksAsync.when(
                    data: (bookmarks) {
                      if (bookmarks.isEmpty)
                        return const _EmptyItem(
                          text: 'No bookmarks for this chapter.',
                        );
                      return Column(
                        children: bookmarks
                            .map(
                              (b) => ListTile(
                                title: Text('Verse ${b.verse}'),
                                subtitle: Text(b.label),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () => ref
                                      .read(bookmarkActionProvider)
                                      .deleteBookmark(b.id),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyItem extends StatelessWidget {
  final String text;
  const _EmptyItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }
}
