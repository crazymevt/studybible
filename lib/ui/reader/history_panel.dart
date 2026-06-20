import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/user_providers.dart';
import '../../app/app_state.dart';
import '../../app/reader_state.dart';

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
            padding: const EdgeInsets.all(16),
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
            child: historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Center(child: Text('No history yet.'));
                }

                return ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
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

                        ref.read(activeToolProvider.notifier).close();
                        if (MediaQuery.sizeOf(context).width <= 900) {
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error loading history')),
            ),
          ),
        ],
      ),
    );
  }
}
