import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../data/content_store.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/tts_providers.dart';
import 'chapter_navigation_footer.dart';
import 'verse_text_builder.dart';
import 'dictionary_panel.dart';
import '../common/breakpoints.dart';

class VerseListView extends ConsumerStatefulWidget {
  final List<Verse> verses;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final Set<int> versesWithNotes;
  final Set<int> versesWithTags;
  final Function(int) onVerseTap;
  final ValueChanged<int>? onFootnoteTap;
  final ValueChanged<String>? onStrongTap;
  final bool showStrongNumbers;
  final ItemScrollController? externalScrollController;
  final ItemPositionsListener? externalPositionsListener;
  final bool showFooter;
  final Map<int, List<String>> subheadings;
  final String? searchQuery;
  final Widget? headerWidget;

  const VerseListView({
    super.key,
    required this.verses,
    required this.selectedVerses,
    required this.savedHighlights,
    this.versesWithNotes = const {},
    this.versesWithTags = const {},
    required this.onVerseTap,
    this.onFootnoteTap,
    this.onStrongTap,
    this.showStrongNumbers = false,
    this.externalScrollController,
    this.externalPositionsListener,
    this.showFooter = true,
    this.subheadings = const {},
    this.searchQuery,
    this.headerWidget,
  });

  @override
  ConsumerState<VerseListView> createState() => _VerseListViewState();
}

class _VerseListViewState extends ConsumerState<VerseListView> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  // Last verse we auto-scrolled to during read-aloud, so we scroll once per
  // verse change rather than on every rebuild.
  int? _lastSpokenScroll;

  // Per-span tap recognizers created by buildVerseSpans (one per word and per
  // punctuation run) across all built rows. Disposed and rebuilt each build()
  // so they don't leak as rows rebuild on selection/scroll.
  final List<GestureRecognizer> _spanRecognizers = [];

  void _disposeSpanRecognizers() {
    for (final r in _spanRecognizers) {
      r.dispose();
    }
    _spanRecognizers.clear();
  }

  @override
  void dispose() {
    _disposeSpanRecognizers();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkScrollTarget();
  }

  @override
  void didUpdateWidget(covariant VerseListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkScrollTarget();
  }

  void _checkScrollTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetVerse = ref.read(targetVerseToScrollProvider);
      if (targetVerse != null) {
        if (!itemScrollController.isAttached) {
          _checkScrollTarget();
          return;
        }
        final targetIndex = widget.verses.indexWhere((v) => v.verse == targetVerse);
        if (targetIndex != -1) {
          final offset = widget.headerWidget != null ? 1 : 0;
          itemScrollController.jumpTo(index: targetIndex + offset);
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
      ref.read(dictionarySearchQueryProvider.notifier).setQuery(word);
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

  List<InlineSpan> _buildVerseSpans(BuildContext context, Verse verse) {
    return buildVerseSpans(
      context: context,
      verse: verse,
      bgColor: null, // List view tileColor handles background
      onVerseTap: widget.onVerseTap,
      onFootnoteTap: widget.onFootnoteTap,
      onStrongTap: widget.onStrongTap,
      showStrongNumbers: widget.showStrongNumbers,
      onWordRightClick: _openDictionary,
      ignoreLeadingBreaks: true,
      searchQuery: widget.searchQuery,
      recognizers: _spanRecognizers,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dispose the prior frame's per-span recognizers before the itemBuilder
    // creates fresh ones for the visible rows, so they don't accumulate.
    _disposeSpanRecognizers();
    final spokenVerse = ref.watch(spokenVerseProvider);

    // Follow read-aloud: scroll the active verse into view as it changes.
    if (spokenVerse != null && spokenVerse != _lastSpokenScroll) {
      _lastSpokenScroll = spokenVerse;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller =
            widget.externalScrollController ?? itemScrollController;
        if (!controller.isAttached) return;
        final idx = widget.verses.indexWhere((v) => v.verse == spokenVerse);
        if (idx != -1) {
          final offset = widget.headerWidget != null ? 1 : 0;
          controller.scrollTo(
            index: idx + offset,
            duration: const Duration(milliseconds: 300),
            alignment: 0.3,
          );
        }
      });
    } else if (spokenVerse == null) {
      _lastSpokenScroll = null;
    }

    return ScrollablePositionedList.builder(
      itemScrollController: widget.externalScrollController ?? itemScrollController,
      itemPositionsListener: widget.externalPositionsListener ?? itemPositionsListener,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      itemCount: widget.verses.length + (widget.showFooter ? 1 : 0) + (widget.headerWidget != null ? 1 : 0),
      itemBuilder: (context, rawIndex) {
        final offset = widget.headerWidget != null ? 1 : 0;
        if (rawIndex == 0 && widget.headerWidget != null) {
          return widget.headerWidget!;
        }
        final index = rawIndex - offset;

        if (widget.showFooter && index == widget.verses.length) {
          return const ChapterNavigationFooter();
        }
        final verse = widget.verses[index];
        final isSelected = widget.selectedVerses.contains(verse.verse);
        final highlightHex = widget.savedHighlights[verse.verse];
        final highlightColor = highlightHex != null
            ? Color(int.parse(highlightHex.replaceFirst('#', '0xFF')))
            : null;

        final isSpoken = spokenVerse == verse.verse;
        final bgColor = isSelected
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5)
            : isSpoken
                ? Theme.of(context)
                    .colorScheme
                    .tertiaryContainer
                    .withValues(alpha: 0.6)
                : highlightColor?.withValues(alpha: 0.2);

        final verseSpacing = ref.watch(appVerseSpacingProvider);
        final verseSubheadings = widget.subheadings[verse.verse] ?? [];

        return Padding(
          padding: EdgeInsets.symmetric(vertical: verseSpacing / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (verseSubheadings.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: verseSubheadings
                        .map((sh) => Text(
                              sh,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ))
                        .toList(),
                  ),
                ),
              ListTile(
                tileColor: bgColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${verse.verse} ',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          // Bump relative to the (delta-applied) label size so
                          // verse numbers stay legible yet still track the
                          // user's font-size setting.
                          fontSize:
                              (Theme.of(context).textTheme.labelSmall?.fontSize ??
                                      11) +
                                  2,
                        ),
                      ),
                      if (widget.versesWithNotes.contains(verse.verse))
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Icon(Icons.edit_note, size: 14, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)),
                          ),
                        ),
                      if (widget.versesWithTags.contains(verse.verse))
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Icon(Icons.label, size: 12, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)),
                          ),
                        ),
                      ..._buildVerseSpans(context, verse),
                    ],
                  ),
                ),
                onTap: () => widget.onVerseTap(verse.verse),
              ),
            ],
          ),
        );
      },
    );
  }
}
