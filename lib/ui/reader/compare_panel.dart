import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/app_state.dart';
import '../../domain/importer/mybible_verse_parser.dart';

class ComparePanel extends ConsumerWidget {
  const ComparePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookName = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final selectedVerses = ref.watch(selectedVersesProvider).toList()..sort();

    if (selectedVerses.isEmpty) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
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
                    'Compare',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (MediaQuery.sizeOf(context).width > 900) {
                        ref.read(activeToolProvider.notifier).close();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('Select verses to compare across versions.'),
              ),
            ),
          ],
        ),
      );
    }

    final compareAsync = ref.watch(compareVersesProvider((
      bookName: bookName,
      chapter: chapter,
      selectedVersesStr: selectedVerses.join(','),
    )));

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
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
                  'Compare ($bookName $chapter)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (MediaQuery.sizeOf(context).width > 900) {
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
            child: compareAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return const Center(child: Text('No verses found.'));
                }
                return ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return _CompareResultCard(
                      result: result,
                      bookName: bookName,
                      chapter: chapter,
                      selectedVerses: selectedVerses,
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

class _CompareResultCard extends ConsumerWidget {
  final CompareResult result;
  final String bookName;
  final int chapter;
  final List<int> selectedVerses;

  const _CompareResultCard({
    required this.result,
    required this.bookName,
    required this.chapter,
    required this.selectedVerses,
  });

  String _formatVerseList(List<int> verses) {
    if (verses.isEmpty) return '';
    final parts = <String>[];
    int start = verses.first;
    int end = verses.first;

    for (int i = 1; i < verses.length; i++) {
      if (verses[i] == end + 1) {
        end = verses[i];
      } else {
        parts.add(start == end ? '$start' : '$start-$end');
        start = verses[i];
        end = verses[i];
      }
    }
    parts.add(start == end ? '$start' : '$start-$end');
    return parts.join(', ');
  }

  Future<void> _copyText(BuildContext context) async {
    final verseNumbers = _formatVerseList(selectedVerses);
    final buffer = StringBuffer();
    buffer.writeln('$bookName $chapter:$verseNumbers (${result.version.id})');

    final parser = MyBibleVerseParser();
    for (final v in result.verses) {
      final cleanText = parser
          .parseVerse(v.textContent)
          .map((s) => s.text)
          .join('')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      buffer.writeln('${v.verse} $cleanText');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied ${result.version.id} to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parser = MyBibleVerseParser();
    
    // Build text spans for the verses
    final spans = <InlineSpan>[];
    for (final v in result.verses) {
      spans.add(
        TextSpan(
          text: '${v.verse} ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
      
      final segments = parser.parseVerse(v.textContent);
      for (final s in segments) {
        spans.add(
          TextSpan(
            text: s.text,
            style: TextStyle(
              fontStyle: s.isItalic ? FontStyle.italic : FontStyle.normal,
              color: s.isJesusWords ? Colors.red.shade300 : null,
            ),
          ),
        );
      }
      spans.add(const TextSpan(text: '\n\n'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${result.version.name} (${result.version.id})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy',
                onPressed: () => _copyText(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText.rich(
            TextSpan(children: spans),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
