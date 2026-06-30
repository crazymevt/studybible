import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/user_providers.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

class HistoryPanel extends ConsumerWidget {
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(navigationHistoryProvider);

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
                  'History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
          ),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history,
                    title: 'No history yet',
                    message: 'Chapters and verses you visit appear here.',
                  );
                }

                return ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final title = item.verse != null
                        ? '${item.bookName} ${item.chapter}:${item.verse}'
                        : '${item.bookName} ${item.chapter}';

                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          item.verseText != null && item.verseText!.isNotEmpty
                          ? Text(
                              item.verseText!
                                  .replaceAll(RegExp(r'<[^>]*>'), '')
                                  .replaceAll(RegExp(r'\s+'), ' ')
                                  .trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () {
                        ref
                            .read(selectedBookNameProvider.notifier)
                            .set(item.bookName);
                        ref
                            .read(selectedChapterProvider.notifier)
                            .set(item.chapter);
                        if (item.verse != null) {
                          ref
                              .read(targetVerseToScrollProvider.notifier)
                              .set(item.verse!);
                          ref.read(selectedVersesProvider.notifier).clear();
                          ref
                              .read(selectedVersesProvider.notifier)
                              .toggle(item.verse!);
                        }

                        // Re-record the visit so the tapped entry is deduped
                        // and re-inserted at the top of the history list.
                        ref
                            .read(navigationControllerProvider)
                            .recordHistory(verse: item.verse);

                        ref.read(activeToolProvider.notifier).close();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const SkeletonList(),
              error: (err, stack) => const EmptyState(
                icon: Icons.error_outline,
                title: 'Couldn\'t load history',
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
