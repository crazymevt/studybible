import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../data/content_store.dart';
import '../../app/reader_state.dart';
import '../../app/app_state.dart';
import 'flowing_paragraph_view.dart';
import 'chapter_navigation_footer.dart';
import 'verse_text_builder.dart';
import 'dictionary_panel.dart';
import '../../app/content_providers.dart';
import '../common/breakpoints.dart';

class ParallelView extends ConsumerStatefulWidget {
  final Map<String, List<Verse>> versesMap;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final Set<int> versesWithNotes;
  final Set<int> versesWithTags;
  final Function(int) onVerseTap;
  final ValueChanged<int>? onFootnoteTap;
  final ValueChanged<String>? onStrongTap;
  final bool showStrongNumbers;
  final bool isFlowing;
  final bool showFooter;
  final Map<int, List<String>> subheadings;
  final String? searchQuery;
  final ItemScrollController? externalScrollController;
  final ItemPositionsListener? externalPositionsListener;
  final Widget? headerWidget;

  const ParallelView({
    super.key,
    required this.versesMap,
    required this.selectedVerses,
    this.versesWithNotes = const {},
    this.versesWithTags = const {},
    required this.savedHighlights,
    required this.onVerseTap,
    this.onFootnoteTap,
    this.onStrongTap,
    this.showStrongNumbers = false,
    this.isFlowing = false,
    this.showFooter = true,
    this.subheadings = const {},
    this.searchQuery,
    this.externalScrollController,
    this.externalPositionsListener,
    this.headerWidget,
  });

  @override
  ConsumerState<ParallelView> createState() => _ParallelViewState();
}

class _ParallelViewState extends ConsumerState<ParallelView> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _checkScrollTarget();
  }

  @override
  void didUpdateWidget(covariant ParallelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkScrollTarget();
  }

  void _checkScrollTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The PageView mounts/unmounts neighbour chapters as it swipes, so this
      // deferred callback (and its self-reschedule below) can fire after this
      // page is gone — touching `ref` then throws.
      if (!mounted) return;
      final targetVerse = ref.read(targetVerseToScrollProvider);
      if (targetVerse != null) {
        if (!itemScrollController.isAttached) {
          _checkScrollTarget();
          return;
        }
        final Set<int> allVerseNumbers = {};
        for (final verses in widget.versesMap.values) {
          allVerseNumbers.addAll(verses.map((v) => v.verse));
        }
        final verseNumbers = allVerseNumbers.toList()..sort();
        final targetIndex = verseNumbers.indexOf(targetVerse);
        if (targetIndex != -1) {
          final offset = widget.headerWidget != null ? 1 : 0;
          itemScrollController.jumpTo(index: targetIndex + offset);
          // Clear it so we don't jump again on rebuild
          ref.read(targetVerseToScrollProvider.notifier).set(null);
        }
      }
    });
  }

  void _openDictionary(String word, Offset position) async {
    // The long-press timer that triggers this can fire after the widget is
    // gone (e.g. a rebuild mid-press), so bail before touching context.
    if (!mounted) return;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'dictionary',
          child: Text('Look up "$word" in Dictionary'),
        ),
      ],
    );

    if (result == 'dictionary') {
      if (!mounted) return;
      ref.read(dictionarySearchQueryProvider.notifier).setQuery(word, exact: true);
      if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
        ref.read(activeToolProvider.notifier).openTool(ActiveTool.dictionary);
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
            child: const DictionaryPanel(),
          ),
        );
      }
    }
  }

  Widget _buildHeader(BuildContext context, String versionId) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          versionId,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ActiveTool>(activeToolProvider, (previous, next) {
      if (previous == ActiveTool.none && next != ActiveTool.none) {
        if (widget.selectedVerses.isNotEmpty) {
          final targetVerse = widget.selectedVerses.first;
          final Set<int> allVerseNumbers = {};
          for (final verses in widget.versesMap.values) {
            allVerseNumbers.addAll(verses.map((v) => v.verse));
          }
          final verseNumbers = allVerseNumbers.toList()..sort();
          final targetIndex = verseNumbers.indexOf(targetVerse);
          if (targetIndex != -1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final controller = widget.externalScrollController ?? itemScrollController;
              if (controller.isAttached) {
                final offset = widget.headerWidget != null ? 1 : 0;
                controller.scrollTo(
                  index: targetIndex + offset,
                  duration: const Duration(milliseconds: 300),
                  alignment: 0.3,
                );
              }
            });
          }
        }
      }
    });

    if (widget.versesMap.isEmpty) {
      return const Center(child: Text('No active versions.'));
    }

    final keys = widget.versesMap.keys.toList();

    if (widget.isFlowing) {
      // Flowing mode: independent columns
      return Row(
        children: keys.map((versionId) {
          final verses = widget.versesMap[versionId] ?? [];
          return Expanded(
            child: Column(
              children: [
                _buildHeader(context, versionId),
                Expanded(
                  child: FlowingParagraphView(
                    verses: verses,
                    selectedVerses: widget.selectedVerses,
                    savedHighlights: widget.savedHighlights,
                    subheadings: widget.subheadings,
                    onVerseTap: widget.onVerseTap,
                    onFootnoteTap: widget.onFootnoteTap,
                    onStrongTap: widget.onStrongTap,
                    showStrongNumbers: widget.showStrongNumbers,
                    showFooter: false,
                    searchQuery: widget.searchQuery,
                    headerWidget: widget.headerWidget,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Verse-by-verse mode: Synchronized scrolling (Row-by-Row layout)
    final Set<int> allVerseNumbers = {};
    for (final verses in widget.versesMap.values) {
      allVerseNumbers.addAll(verses.map((v) => v.verse));
    }
    final verseNumbers = allVerseNumbers.toList()..sort();

    return Column(
      children: [
        Row(
          children: keys.map((versionId) {
            return Expanded(child: _buildHeader(context, versionId));
          }).toList(),
        ),
        Expanded(
          child: ScrollablePositionedList.builder(
            itemScrollController: widget.externalScrollController ?? itemScrollController,
            itemPositionsListener: widget.externalPositionsListener ?? itemPositionsListener,
            itemCount: verseNumbers.length + (widget.showFooter ? 1 : 0) + (widget.headerWidget != null ? 1 : 0),
            itemBuilder: (context, rawIndex) {
              final offset = widget.headerWidget != null ? 1 : 0;
              if (rawIndex == 0 && widget.headerWidget != null) {
                return widget.headerWidget!;
              }
              final index = rawIndex - offset;

              if (index == verseNumbers.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: ChapterNavigationFooter(),
                );
              }

              final verseNum = verseNumbers[index];
              final isSelected = widget.selectedVerses.contains(verseNum);
              final highlightHex = widget.savedHighlights[verseNum];
              final highlightColor = highlightHex != null
                  ? Color(int.parse(highlightHex.replaceFirst('#', '0xFF')))
                  : null;

              final bgColor = isSelected
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : highlightColor?.withValues(alpha: 0.2);

              final verseSpacing = ref.watch(appVerseSpacingProvider);
              final verseSubheadings = widget.subheadings[verseNum] ?? [];

              // Resolve each column's verse (or a placeholder when a
              // translation is missing it), in the same order as the headers.
              final rowVerses = keys.map((versionId) {
                final verses = widget.versesMap[versionId] ?? [];
                return verses.firstWhere(
                  (v) => v.verse == verseNum,
                  orElse: () => Verse(
                    id: -1,
                    bookId: -1,
                    chapter: -1,
                    verse: verseNum,
                    textContent: '',
                    segments: '[]',
                  ),
                );
              }).toList();

              return _ParallelVerseRow(
                key: ValueKey(verseNum),
                verseNum: verseNum,
                verses: rowVerses,
                bgColor: bgColor,
                subheadings: verseSubheadings,
                verseSpacing: verseSpacing,
                showStrongNumbers: widget.showStrongNumbers,
                searchQuery: widget.searchQuery,
                onVerseTap: widget.onVerseTap,
                onFootnoteTap: widget.onFootnoteTap,
                onStrongTap: widget.onStrongTap,
                onWordRightClick: _openDictionary,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One synchronized row across all parallel translations. Owns the per-span
/// tap recognizers that [buildVerseSpans] creates for every column's words, so
/// they are disposed when this row leaves the list and rebuilt only when this
/// row rebuilds — no accumulation across scrolling.
class _ParallelVerseRow extends StatefulWidget {
  final int verseNum;
  final List<Verse> verses;
  final Color? bgColor;
  final List<String> subheadings;
  final double verseSpacing;
  final bool showStrongNumbers;
  final String? searchQuery;
  final Function(int) onVerseTap;
  final ValueChanged<int>? onFootnoteTap;
  final ValueChanged<String>? onStrongTap;
  final Function(String, Offset) onWordRightClick;

  const _ParallelVerseRow({
    super.key,
    required this.verseNum,
    required this.verses,
    required this.bgColor,
    required this.subheadings,
    required this.verseSpacing,
    required this.showStrongNumbers,
    required this.searchQuery,
    required this.onVerseTap,
    required this.onFootnoteTap,
    required this.onStrongTap,
    required this.onWordRightClick,
  });

  @override
  State<_ParallelVerseRow> createState() => _ParallelVerseRowState();
}

class _ParallelVerseRowState extends State<_ParallelVerseRow> {
  final List<GestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dispose the previous build's recognizers before creating fresh ones.
    _disposeRecognizers();
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.verseSpacing / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.subheadings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.subheadings
                    .map((sh) => Text(
                          sh,
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.primary,
                              ),
                          textAlign: TextAlign.center,
                        ))
                    .toList(),
              ),
            ),
          Container(
            color: widget.bgColor,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.verses.map((verse) {
                  return Expanded(
                    child: InkWell(
                      onTap: () => widget.onVerseTap(widget.verseNum),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: verse.id == -1
                            ? const SizedBox.shrink() // empty cell if verse is missing in this translation
                            : Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${verse.verse} ',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            // Bump relative to the
                                            // (delta-applied) label size so
                                            // verse numbers track the user's
                                            // font setting.
                                            fontSize: (theme.textTheme.labelSmall
                                                        ?.fontSize ??
                                                    11) +
                                                2,
                                          ),
                                    ),
                                    ...buildVerseSpans(
                                      context: context,
                                      verse: verse,
                                      bgColor: null,
                                      onVerseTap: widget.onVerseTap,
                                      onFootnoteTap: widget.onFootnoteTap,
                                      onStrongTap: widget.onStrongTap,
                                      showStrongNumbers: widget.showStrongNumbers,
                                      onWordRightClick: widget.onWordRightClick,
                                      searchQuery: widget.searchQuery,
                                      ignoreLeadingBreaks: true,
                                      recognizers: _recognizers,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
