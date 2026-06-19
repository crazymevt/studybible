import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../app/search_providers.dart';
import '../../app/content_providers.dart';
import '../../app/app_state.dart';
import '../../app/reader_state.dart';
import 'dictionary_panel.dart';
import 'commentary_panel.dart';

class SearchPanel extends ConsumerStatefulWidget {
  const SearchPanel({super.key});

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(globalSearchResultsProvider);

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Global Search',
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
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search entire library...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    ref.read(globalSearchQueryProvider.notifier).setQuery(value);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              data: (results) {
                if (results.isEmpty && _controller.text.isNotEmpty) {
                  return const Center(child: Text('No results found.'));
                } else if (results.isEmpty) {
                  return const Center(child: Text('Type a word to search.'));
                }

                final verses = results.where((r) => r.type == 'verse').toList();
                final notes = results.where((r) => r.type == 'note').toList();
                final commentaries = results.where((r) => r.type == 'commentary').toList();
                final dictionaries = results.where((r) => r.type == 'dictionary').toList();

                return DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(text: 'Verses (${verses.length})'),
                          Tab(text: 'Notes (${notes.length})'),
                          Tab(text: 'Comm. (${commentaries.length})'),
                          Tab(text: 'Dict. (${dictionaries.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _ResultsList(results: verses),
                            _ResultsList(results: notes),
                            _GroupedResultsList(results: commentaries),
                            _GroupedResultsList(results: dictionaries),
                          ],
                        ),
                      ),
                    ],
                  ),
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

class _ResultsList extends ConsumerWidget {
  final List<SearchResult> results;
  const _ResultsList({required this.results});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (results.isEmpty) {
      return const Center(child: Text('No results in this category.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final item = results[index];
        return InkWell(
          onTap: () {
            if (item.type == 'verse' || item.type == 'note') {
              if (item.book != null) {
                ref.read(selectedBookNameProvider.notifier).set(item.book!);
                if (item.chapter != null) {
                  ref.read(selectedChapterProvider.notifier).set(item.chapter!);
                }
                if (MediaQuery.sizeOf(context).width <= 800) {
                  Navigator.of(context).pop();
                }
              }
            } else if (item.type == 'dictionary') {
              ref.read(dictionarySearchQueryProvider.notifier).setQuery(item.title);
              if (MediaQuery.sizeOf(context).width <= 800) {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 1.0,
                    expand: false,
                    builder: (_, scrollController) => const DictionaryPanel(),
                  ),
                );
              } else {
                ref.read(activeToolProvider.notifier).setTool(ActiveTool.dictionary);
              }
            } else if (item.type == 'commentary') {
              if (item.book != null && item.book != 'General') {
                ref.read(selectedBookNameProvider.notifier).set(item.book!);
                if (item.chapter != null) {
                  ref.read(selectedChapterProvider.notifier).set(item.chapter!);
                }
              }
              if (MediaQuery.sizeOf(context).width <= 800) {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 1.0,
                    expand: false,
                    builder: (_, scrollController) => const CommentaryPanel(),
                  ),
                );
              } else {
                ref.read(activeToolProvider.notifier).setTool(ActiveTool.commentaries);
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (item.type == 'commentary' || item.type == 'dictionary')
                HtmlWidget(item.textContent, textStyle: Theme.of(context).textTheme.bodyMedium)
              else
                Text(item.textContent, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }
}

class _GroupedResultsList extends ConsumerWidget {
  final List<SearchResult> results;
  const _GroupedResultsList({required this.results});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (results.isEmpty) {
      return const Center(child: Text('No results in this category.'));
    }

    // Group results by sourceName
    final Map<String, List<SearchResult>> grouped = {};
    for (final r in results) {
      final key = r.sourceName ?? 'Unknown Source';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    return ListView.builder(
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final sourceName = grouped.keys.elementAt(index);
        final sourceResults = grouped[sourceName]!;

        return ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            '$sourceName (${sourceResults.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: sourceResults.map((item) {
            return InkWell(
              onTap: () {
                if (item.type == 'dictionary') {
                  ref.read(dictionarySearchQueryProvider.notifier).setQuery(item.title);
                  if (MediaQuery.sizeOf(context).width <= 800) {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.9,
                        minChildSize: 0.5,
                        maxChildSize: 1.0,
                        expand: false,
                        builder: (_, scrollController) => const DictionaryPanel(),
                      ),
                    );
                  } else {
                    ref.read(activeToolProvider.notifier).setTool(ActiveTool.dictionary);
                  }
                } else if (item.type == 'commentary') {
                  if (item.book != null && item.book != 'General') {
                    ref.read(selectedBookNameProvider.notifier).set(item.book!);
                    if (item.chapter != null) {
                      ref.read(selectedChapterProvider.notifier).set(item.chapter!);
                    }
                  }
                  if (MediaQuery.sizeOf(context).width <= 800) {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.9,
                        minChildSize: 0.5,
                        maxChildSize: 1.0,
                        expand: false,
                        builder: (_, scrollController) => const CommentaryPanel(),
                      ),
                    );
                  } else {
                    ref.read(activeToolProvider.notifier).setTool(ActiveTool.commentaries);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    HtmlWidget(item.textContent, textStyle: Theme.of(context).textTheme.bodyMedium),
                    const Divider(height: 24),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
