import 'package:flutter/material.dart';
import '../../data/content_store.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import 'chapter_navigation_footer.dart';
import 'verse_text_builder.dart';
import 'dictionary_panel.dart';

class VerseListView extends ConsumerStatefulWidget {
  final List<Verse> verses;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final Set<int> versesWithNotes;
  final Set<int> versesWithTags;
  final Function(int) onVerseTap;
  final ValueChanged<int>? onFootnoteTap;
  final ItemScrollController? externalScrollController;
  final ItemPositionsListener? externalPositionsListener;
  final bool showFooter;
  final Map<int, List<String>> subheadings;
  final String? searchQuery;

  const VerseListView({
    super.key,
    required this.verses,
    required this.selectedVerses,
    required this.savedHighlights,
    this.versesWithNotes = const {},
    this.versesWithTags = const {},
    required this.onVerseTap,
    this.onFootnoteTap,
    this.externalScrollController,
    this.externalPositionsListener,
    this.showFooter = true,
    this.subheadings = const {},
    this.searchQuery,
  });

  @override
  ConsumerState<VerseListView> createState() => _VerseListViewState();
}

class _VerseListViewState extends ConsumerState<VerseListView> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

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
        final targetIndex = widget.verses.indexWhere(
          (v) => v.verse == targetVerse,
        );
        if (targetIndex != -1) {
          itemScrollController.jumpTo(index: targetIndex);
          ref.read(targetVerseToScrollProvider.notifier).set(null);
        }
      }
    });
  }

  void _openDictionary(String word, Offset position) async {
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
      ref.read(dictionarySearchQueryProvider.notifier).setQuery(word);
      if (MediaQuery.sizeOf(context).width > 800) {
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
      onWordRightClick: _openDictionary,
      ignoreLeadingBreaks: true,
      searchQuery: widget.searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      itemCount: widget.verses.length + (widget.showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.showFooter && index == widget.verses.length) {
          return const ChapterNavigationFooter();
        }
        final verse = widget.verses[index];
        final isSelected = widget.selectedVerses.contains(verse.verse);
        final highlightHex = widget.savedHighlights[verse.verse];
        final highlightColor = highlightHex != null
            ? Color(int.parse(highlightHex.replaceFirst('#', '0xFF')))
            : null;

        final bgColor = isSelected
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5)
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
