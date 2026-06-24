import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../app/user_providers.dart';
import '../../app/reader_state.dart';

class NoteEditorDialog extends ConsumerStatefulWidget {
  final Set<int> verses;

  const NoteEditorDialog({super.key, required this.verses});

  @override
  ConsumerState<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends ConsumerState<NoteEditorDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingNote();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadExistingNote() async {
    final store = ref.read(userStoreProvider);
    final bookName = ref.read(selectedBookNameProvider);
    final chapter = ref.read(selectedChapterProvider);

    final query = store.select(store.notes)
      ..where(
        (n) =>
            (n.bookName.equals(bookName)) &
            (n.chapter.equals(chapter)) &
            (n.deleted.equals(false)),
      );

    if (widget.verses.isNotEmpty) {
      final sortedVerses = widget.verses.toList()..sort();
      final versesString = sortedVerses.join(', ');
      final primaryVerse = sortedVerses.first;
      
      if (widget.verses.length == 1) {
        query.where((n) => n.selectedVerses.equals(versesString) | (n.selectedVerses.isNull() & n.verse.equals(primaryVerse)));
      } else {
        query.where((n) => n.selectedVerses.equals(versesString));
      }
    } else {
      query.where((n) => n.verse.isNull() & n.selectedVerses.isNull());
    }

    final existing = await query.getSingleOrNull();
    if (existing != null && mounted) {
      _controller.text = existing.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.verses.isEmpty
        ? 'Chapter Note'
        : widget.verses.length == 1
            ? 'Note for Verse ${widget.verses.first}'
            : 'Note for Verses ${(widget.verses.toList()..sort()).join(', ')}';

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 8,
        decoration: const InputDecoration(
          hintText: 'Enter markdown note...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: () async {
            if (_controller.text.isNotEmpty) {
              await ref
                  .read(noteActionProvider)
                  .saveNote(widget.verses, _controller.text);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
