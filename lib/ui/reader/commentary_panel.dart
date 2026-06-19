import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../app/content_providers.dart';
import '../../app/app_state.dart';

class CommentaryPanel extends ConsumerWidget {
  const CommentaryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(commentaryEntriesProvider);

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
                  'Commentaries',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        ref.watch(showBookIntroProvider) ? Icons.auto_stories : Icons.info_outline,
                        color: ref.watch(showBookIntroProvider) ? Theme.of(context).colorScheme.primary : null,
                      ),
                      tooltip: 'Toggle Book Introduction',
                      onPressed: () {
                        ref.read(showBookIntroProvider.notifier).toggle();
                      },
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
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(child: Text('No commentary available.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: HtmlWidget(
                            entry.textContent,
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (index < entries.length - 1)
                          const Divider(),
                      ],
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
