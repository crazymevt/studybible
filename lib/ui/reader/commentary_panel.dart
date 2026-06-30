
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../app/content_providers.dart';
import '../../app/app_state.dart';
import '../../app/reader_state.dart';
import '../common/bible_link_handler.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

class CommentaryPanel extends ConsumerWidget {
  const CommentaryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(commentaryEntriesProvider);
    final commentariesAsync = ref.watch(commentariesProvider);
    final selectedVerses = ref.watch(selectedVersesProvider);

    final commentariesMap = commentariesAsync.value?.fold<Map<int, String>>(
      {},
      (map, c) => map..[c.id] = c.abbreviation,
    ) ?? {};

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
              children: [
                Text(
                  'Commentaries',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final commentariesAsync = ref.watch(
                              commentariesProvider,
                            );
                            final selectedId = ref.watch(
                              selectedCommentaryProvider,
                            );

                            return commentariesAsync.when(
                              data: (commentaries) {
                                if (commentaries.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                // Auto-select first if none selected
                                if (selectedId == null) {
                                  Future.microtask(
                                    () => ref
                                        .read(selectedCommentaryProvider.notifier)
                                        .set(commentaries.first.id),
                                  );
                                }

                                return DropdownButton<int>(
                                  isExpanded: true,
                                  value: selectedId ?? commentaries.first.id,
                                  underline: const SizedBox(),
                                  items: commentaries
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.abbreviation, overflow: TextOverflow.ellipsis),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    ref
                                        .read(selectedCommentaryProvider.notifier)
                                        .set(val);
                                  },
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (context, ref, _) {
                          final hasIntro = ref.watch(hasBookIntroProvider).value ?? false;
                          if (!hasIntro) return const SizedBox.shrink();
                          
                          return IconButton(
                            icon: Icon(
                              ref.watch(showBookIntroProvider)
                                  ? Icons.auto_stories
                                  : Icons.info_outline,
                              color: ref.watch(showBookIntroProvider)
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            tooltip: 'Toggle Book Introduction',
                            onPressed: () {
                              ref.read(showBookIntroProvider.notifier).toggle();
                            },
                          );
                        },
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
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'No commentary here',
                    message:
                        'Select a verse, or pick another commentary, to see notes for this passage.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (entry.verse != null && entry.verse! > 0)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 4.0,
                            ),
                            child: Text(
                              selectedVerses.isNotEmpty
                                  ? '${commentariesMap[entry.commentaryId] ?? 'Commentary'} - Verse ${entry.verse}'
                                  : 'Verse ${entry.verse}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: HtmlWidget(
                            entry.textContent,
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                            onErrorBuilder: (context, element, error) => const SizedBox.shrink(),
                            onLoadingBuilder: (context, element, progress) => const SizedBox.shrink(),
                            onTapUrl: (url) =>
                                handleBibleRefTap(ref, context, url),
                          ),
                        ),
                        if (index < entries.length - 1) const Divider(),
                      ],
                    );
                  },
                );
              },
              loading: () => const SkeletonList(),
              error: (err, stack) => const EmptyState(
                icon: Icons.error_outline,
                title: 'Couldn\'t load commentary',
                message: 'Something went wrong loading this commentary.',
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
