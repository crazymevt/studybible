import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../data/content_store.dart';
import '../../app/app_state.dart';

class CrossReferencePanel extends ConsumerWidget {
  const CrossReferencePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedVerses = ref.watch(selectedVersesProvider);
    final bookName = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);

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
                  'Cross-References',
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
          if (selectedVerses.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Select a verse to view cross-references.'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: selectedVerses.length,
                itemBuilder: (context, index) {
                  final verseId = selectedVerses.elementAt(index);
                  return _CrossReferenceListForVerse(
                    bookName: bookName,
                    chapter: chapter,
                    verse: verseId,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CrossReferenceListForVerse extends ConsumerWidget {
  final String bookName;
  final int chapter;
  final int verse;

  const _CrossReferenceListForVerse({
    required this.bookName,
    required this.chapter,
    required this.verse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xrefsAsync = ref.watch(crossReferencesProvider(verse));

    return xrefsAsync.when(
      data: (xrefs) {
        if (xrefs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No cross-references found for this verse.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Cross-References for $bookName $chapter:$verse',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...xrefs.map((xref) => _CrossReferenceItem(xref: xref)),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}

class _CrossReferenceItem extends ConsumerWidget {
  final CrossReference xref;

  const _CrossReferenceItem({required this.xref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetVerseAsync = ref.watch(crossReferenceVerseProvider(xref));
    
    final label = '${xref.targetBookName} ${xref.targetChapter}:${xref.targetVerse}';

    return targetVerseAsync.when(
      data: (targetVerse) {
        if (targetVerse == null) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: Colors.white, // From mockup
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: const Color(0xFF4A60D1), // Blue edge
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedBookNameProvider.notifier).set(xref.targetBookName);
                      ref.read(selectedChapterProvider.notifier).set(xref.targetChapter);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                label,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFF4A60D1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            targetVerse.textContent,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
