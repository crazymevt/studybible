
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../app/content_providers.dart';
import '../../app/app_state.dart';
import '../../app/reader_state.dart';
import '../../data/mybible_book_map.dart';

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
                            onTapUrl: (url) {
                              try {
                                int? b, c, v;

                                // Try query parameters first (e.g. b/?b=10&c=1&v=1)
                                final uri = Uri.tryParse(url);
                                if (uri != null &&
                                    (uri.queryParameters.containsKey('b') ||
                                        uri.queryParameters.containsKey('B'))) {
                                  b = int.tryParse(
                                    uri.queryParameters['b'] ??
                                        uri.queryParameters['B'] ??
                                        '',
                                  );
                                  c = int.tryParse(
                                    uri.queryParameters['c'] ??
                                        uri.queryParameters['C'] ??
                                        '',
                                  );
                                  v = int.tryParse(
                                    uri.queryParameters['v'] ??
                                        uri.queryParameters['V'] ??
                                        '',
                                  );
                                } else {
                                  // Try generic format with any non-digit delimiters (e.g. b:10/1/1 or B: 10 1 1)
                                  final match = RegExp(
                                    r'^(?:b|bible):[^\d]*(\d+)(?:[^\d]+(\d+))?(?:[^\d]+(\d+))?',
                                    caseSensitive: false,
                                  ).firstMatch(url);
                                  if (match != null) {
                                    b = match.group(1) != null
                                        ? int.tryParse(match.group(1)!)
                                        : null;
                                    c = match.group(2) != null
                                        ? int.tryParse(match.group(2)!)
                                        : null;
                                    v = match.group(3) != null
                                        ? int.tryParse(match.group(3)!)
                                        : null;
                                  }
                                }

                                if (b != null) {
                                  final bookName =
                                      mybibleBookMap[b] ??
                                      mybibleBookMap[b *
                                          10]; // Fallback to * 10
                                  if (bookName != null) {
                                    ref
                                        .read(selectedBookNameProvider.notifier)
                                        .set(bookName);
                                    if (c != null && c > 0) {
                                      ref
                                          .read(
                                            selectedChapterProvider.notifier,
                                          )
                                          .set(c);
                                    }
                                    if (v != null && v > 0) {
                                      ref
                                          .read(selectedVersesProvider.notifier)
                                          .clear();
                                      ref
                                          .read(selectedVersesProvider.notifier)
                                          .toggle(v);
                                    }

                                    // Record history
                                    ref
                                        .read(navigationControllerProvider)
                                        .recordHistory(verse: v);

                                    // Also close the tool panel so they can read the verse
                                    ref
                                        .read(activeToolProvider.notifier)
                                        .close();
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unknown book number: $b from $url',
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not parse link: $url',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error parsing url $url: $e'),
                                  ),
                                );
                              }
                              return true;
                            },
                          ),
                        ),
                        if (index < entries.length - 1) const Divider(),
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
