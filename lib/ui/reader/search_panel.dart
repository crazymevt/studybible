import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../app/search_providers.dart';
import '../../app/content_providers.dart';
import '../../app/app_state.dart';
import '../../app/reader_state.dart';
import '../../app/sermon_providers.dart';
import 'dictionary_panel.dart';
import 'commentary_panel.dart';
import 'notes_panel.dart';
import '../sermons/sermon_editor_screen.dart';
import '../tags/tags_tab_view.dart';
import '../journals/journals_list_panel.dart';

class SearchPanel extends ConsumerStatefulWidget {
  const SearchPanel({super.key});

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(globalSearchResultsProvider);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DefaultTabController(
        length: 2,
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
                  focusNode: _focusNode,
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
                    ref
                        .read(globalSearchQueryProvider.notifier)
                        .setQuery(value);
                  },
                ),
                const SizedBox(height: 16),
                const TabBar(
                  tabs: [
                    Tab(text: 'Text Search'),
                    Tab(text: 'Tags'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                resultsAsync.when(
              data: (results) {
                if (results.isEmpty && _controller.text.isNotEmpty) {
                  return const Center(child: Text('No results found.'));
                } else if (results.isEmpty) {
                  return const Center(child: Text('Type a word to search.'));
                }

                final verses = results.where((r) => r.type == 'verse').toList();
                final notes = results.where((r) => r.type == 'note').toList();
                final sermons = results.where((r) => r.type == 'sermon').toList();
                final journals = results.where((r) => r.type == 'journal').toList();
                final prayers = results.where((r) => r.type == 'prayer').toList();
                final commentaries = results
                    .where((r) => r.type == 'commentary')
                    .toList();
                final dictionaries = results
                    .where((r) => r.type == 'dictionary')
                    .toList();

                return DefaultTabController(
                  length: 7,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(text: 'Verses (${verses.length})'),
                          Tab(text: 'Notes (${notes.length})'),
                          Tab(text: 'Sermons (${sermons.length})'),
                          Tab(text: 'Journals (${journals.length})'),
                          Tab(text: 'Prayers (${prayers.length})'),
                          Tab(text: 'Comm. (${commentaries.length})'),
                          Tab(text: 'Dict. (${dictionaries.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            SearchResultsList(results: verses),
                            SearchResultsList(results: notes),
                            SearchResultsList(results: sermons),
                            SearchResultsList(results: journals),
                            SearchResultsList(results: prayers),
                            GroupedSearchResultsList(results: commentaries),
                            GroupedSearchResultsList(results: dictionaries),
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
            const TagsTabView(),
          ],
        ),
      ),
      ],
    ),
    ),
    );
  }
}

class SearchResultsList extends ConsumerWidget {
  final List<SearchResult> results;
  const SearchResultsList({required this.results});

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
                
                if (item.selectedVerses != null) {
                  ref.read(selectedVersesProvider.notifier).clear();
                  final versesToSelect = item.selectedVerses!
                      .split(',')
                      .map((e) => int.tryParse(e.trim()) ?? 0)
                      .where((e) => e > 0)
                      .toList();
                  for (final v in versesToSelect) {
                    ref.read(selectedVersesProvider.notifier).toggle(v);
                  }
                  if (versesToSelect.isNotEmpty) {
                    ref
                        .read(targetVerseToScrollProvider.notifier)
                        .set(versesToSelect.first);
                    ref
                        .read(navigationControllerProvider)
                        .recordHistory(verse: versesToSelect.first);
                  }
                } else if (item.verse != null) {
                  ref
                      .read(targetVerseToScrollProvider.notifier)
                      .set(item.verse!);
                  ref.read(selectedVersesProvider.notifier).clear();
                  ref.read(selectedVersesProvider.notifier).toggle(item.verse!);
                  ref
                      .read(navigationControllerProvider)
                      .recordHistory(verse: item.verse);
                } else {
                  ref.read(navigationControllerProvider).recordHistory();
                }

                if (MediaQuery.sizeOf(context).width <= 900) {
                  Navigator.of(context).pop();
                }
                
                if (item.type == 'note') {
                  if (MediaQuery.sizeOf(context).width > 900) {
                    ref.read(activeToolProvider.notifier).setTool(ActiveTool.notes);
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => Container(
                        height: MediaQuery.sizeOf(context).height * 0.8,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const NotesPanel(),
                      ),
                    );
                  }
                }
              }
            } else if (item.type == 'sermon') {
              if (MediaQuery.sizeOf(context).width <= 900) {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SermonEditorScreen(sermonId: item.referenceId, isFullScreen: true),
                ));
              } else {
                ref.read(selectedSermonIdProvider.notifier).set(item.referenceId);
                ref.read(activeToolProvider.notifier).setTool(ActiveTool.sermons);
              }
            } else if (item.type == 'dictionary') {
              ref
                  .read(dictionarySearchQueryProvider.notifier)
                  .setQuery(item.title);
              if (MediaQuery.sizeOf(context).width <= 900) {
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
                ref
                    .read(activeToolProvider.notifier)
                    .setTool(ActiveTool.dictionary);
              }
            } else if (item.type == 'journal') {
              ref.read(selectedJournalIdProvider.notifier).setId(item.referenceId);
              if (MediaQuery.sizeOf(context).width <= 900) {
                Navigator.of(context).pop();
              }
              ref.read(appModuleProvider.notifier).setModule(AppModule.journalsPrayers);
            } else if (item.type == 'prayer') {
              if (MediaQuery.sizeOf(context).width <= 900) {
                Navigator.of(context).pop();
              }
              ref.read(appModuleProvider.notifier).setModule(AppModule.journalsPrayers);
            } else if (item.type == 'commentary') {
              if (item.book != null && item.book != 'General') {
                ref.read(selectedBookNameProvider.notifier).set(item.book!);
                if (item.chapter != null) {
                  ref.read(selectedChapterProvider.notifier).set(item.chapter!);
                }
                ref.read(navigationControllerProvider).recordHistory();
              }
              if (MediaQuery.sizeOf(context).width <= 900) {
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
                ref
                    .read(activeToolProvider.notifier)
                    .setTool(ActiveTool.commentaries);
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
                HtmlWidget(
                  item.textContent,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Text(
                  item.textContent,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        );
      },
    );
  }
}

class GroupedSearchResultsList extends ConsumerWidget {
  final List<SearchResult> results;
  const GroupedSearchResultsList({required this.results});

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
                  ref
                      .read(dictionarySearchQueryProvider.notifier)
                      .setQuery(item.title);
                  if (MediaQuery.sizeOf(context).width <= 900) {
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
                        builder: (_, scrollController) =>
                            const DictionaryPanel(),
                      ),
                    );
                  } else {
                    ref
                        .read(activeToolProvider.notifier)
                        .setTool(ActiveTool.dictionary);
                  }
                } else if (item.type == 'commentary') {
                  if (item.book != null && item.book != 'General') {
                    ref.read(selectedBookNameProvider.notifier).set(item.book!);
                    if (item.chapter != null) {
                      ref
                          .read(selectedChapterProvider.notifier)
                          .set(item.chapter!);
                      ref.read(navigationControllerProvider).recordHistory();
                    }
                  }
                  if (MediaQuery.sizeOf(context).width <= 900) {
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
                        builder: (_, scrollController) =>
                            const CommentaryPanel(),
                      ),
                    );
                  } else {
                    ref
                        .read(activeToolProvider.notifier)
                        .setTool(ActiveTool.commentaries);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                    HtmlWidget(
                      item.textContent,
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                    ),
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
