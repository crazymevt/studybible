import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/topic_providers.dart';
import '../../data/content_store.dart';
import '../common/breakpoints.dart';

/// Open [topicId] in the Topics tool: the side panel on wide layouts, a
/// bottom sheet on phones.
void openTopicInPanel(BuildContext context, WidgetRef ref, int topicId) {
  ref.read(selectedTopicProvider.notifier).select(topicId);
  if (context.isWideLayout) {
    ref.read(activeToolProvider.notifier).openTool(ActiveTool.topics);
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.sizeOf(context).height * 0.85,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: const TopicsPanel(),
      ),
    );
  }
}

/// Bottom sheet listing the topics that reference a given verse (reverse
/// lookup from the verse action bar).
class TopicsForVerseSheet extends ConsumerWidget {
  const TopicsForVerseSheet({
    super.key,
    required this.book,
    required this.chapter,
    required this.verse,
  });

  final String book;
  final int chapter;
  final int verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(
      topicsForVerseProvider((book: book, chapter: chapter, verse: verse)),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Topics for $book $chapter:$verse',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: topics.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e'),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No topics reference this verse.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final t = list[i];
                      return ListTile(
                        dense: true,
                        title: Text(_titleCase(t.topicName)),
                        subtitle: t.description.isEmpty
                            ? null
                            : Text(t.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.of(context).maybePop();
                          openTopicInPanel(context, ref, t.topicId);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nave's Topical Bible browser: search topics, drill into a topic's subtopics,
/// and tap a scripture reference to jump there.
class TopicsPanel extends ConsumerStatefulWidget {
  const TopicsPanel({super.key});

  @override
  ConsumerState<TopicsPanel> createState() => _TopicsPanelState();
}

class _TopicsPanelState extends ConsumerState<TopicsPanel> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(topicSearchQueryProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _refLabel(TopicReference r) {
    var s = '${r.bookName} ${r.chapter}';
    if (r.verse != null) {
      s += ':${r.verse}';
      if (r.verseEnd != null) s += '-${r.verseEnd}';
    }
    return s;
  }

  void _goToRef(TopicReference r) {
    final verse = r.verse ?? 1;
    ref.read(selectedBookNameProvider.notifier).set(r.bookName);
    ref.read(selectedChapterProvider.notifier).set(r.chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(verse);
    ref.read(selectedVersesProvider.notifier).clear();
    if (r.verse != null) ref.read(selectedVersesProvider.notifier).toggle(verse);
    ref.read(navigationControllerProvider).recordHistory(verse: verse);
    if (MediaQuery.sizeOf(context).width <= Breakpoints.compact) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _openTopicByName(String name) async {
    // Prefer opening the target topic directly; only fall back to a search if
    // there's no exact match for the cross-reference.
    final id = await ref.read(topicIdByNameProvider(name).future);
    if (!mounted) return;
    if (id != null) {
      ref.read(selectedTopicProvider.notifier).select(id);
    } else {
      final normalized = name.trim().toUpperCase();
      _controller.text = normalized;
      ref.read(topicSearchQueryProvider.notifier).setQuery(normalized);
      ref.read(selectedTopicProvider.notifier).select(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTopic = ref.watch(selectedTopicProvider);
    final ready = ref.watch(topicalIndexReadyProvider);

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (selectedTopic != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back to results',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => ref
                                .read(selectedTopicProvider.notifier)
                                .select(null),
                          ),
                        Text(
                          'Topics',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
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
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Search topics (e.g. Faith, Prayer)…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    ref.read(topicSearchQueryProvider.notifier).setQuery(v);
                    if (selectedTopic != null) {
                      ref.read(selectedTopicProvider.notifier).select(null);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ready.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load topics: $e')),
              data: (_) => selectedTopic != null
                  ? _TopicDetailView(
                      topicId: selectedTopic,
                      refLabel: _refLabel,
                      onRefTap: _goToRef,
                      onSeeAlso: _openTopicByName,
                    )
                  : const _TopicSearchResults(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicSearchResults extends ConsumerWidget {
  const _TopicSearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(topicSearchQueryProvider).trim();
    if (query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Search Nave\'s Topical Bible — over 5,000 topics with cross-referenced verses.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    final results = ref.watch(topicSearchResultsProvider);
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (topics) {
        if (topics.isEmpty) {
          return Center(child: Text('No topics matching "$query".'));
        }
        return ListView.builder(
          itemCount: topics.length,
          itemBuilder: (context, i) {
            final t = topics[i];
            return ListTile(
              dense: true,
              title: Text(_titleCase(t.name)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () =>
                  ref.read(selectedTopicProvider.notifier).select(t.id),
            );
          },
        );
      },
    );
  }
}

class _TopicDetailView extends ConsumerWidget {
  const _TopicDetailView({
    required this.topicId,
    required this.refLabel,
    required this.onRefTap,
    required this.onSeeAlso,
  });

  final int topicId;
  final String Function(TopicReference) refLabel;
  final void Function(TopicReference) onRefTap;
  final void Function(String) onSeeAlso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(topicDetailProvider(topicId));
    final scheme = Theme.of(context).colorScheme;
    return detail.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (d) {
        if (d == null) return const SizedBox.shrink();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: d.entries.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  _titleCase(d.topic.name),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                ),
              );
            }
            final ev = d.entries[i - 1];
            final see = ev.entry.seeAlso?.split('\n') ?? const [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ev.entry.description.isNotEmpty)
                    Text(
                      ev.entry.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (ev.refs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ev.refs
                            .map((r) => ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(refLabel(r)),
                                  onPressed: () => onRefTap(r),
                                ))
                            .toList(),
                      ),
                    ),
                  for (final s in see)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: InkWell(
                        onTap: () => onSeeAlso(s),
                        child: Text(
                          'See also ${_titleCase(s)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Nave's topics are stored upper-cased; show them in title case for display.
String _titleCase(String s) {
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
