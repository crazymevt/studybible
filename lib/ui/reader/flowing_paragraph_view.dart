import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../data/content_store.dart';
import 'chapter_navigation_footer.dart';
import 'dictionary_panel.dart';
import 'verse_text_builder.dart';

class FlowingParagraphView extends ConsumerStatefulWidget {
  final List<Verse> verses;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final Set<int> versesWithNotes;
  final Set<int> versesWithTags;
  final ValueChanged<int> onVerseTap;
  final ValueChanged<int>? onFootnoteTap;
  final bool showFooter;
  final Map<int, List<String>> subheadings;

  const FlowingParagraphView({
    super.key,
    required this.verses,
    required this.selectedVerses,
    required this.savedHighlights,
    this.versesWithNotes = const {},
    this.versesWithTags = const {},
    required this.onVerseTap,
    this.onFootnoteTap,
    this.showFooter = true,
    this.subheadings = const {},
  });

  @override
  ConsumerState<FlowingParagraphView> createState() =>
      _FlowingParagraphViewState();
}

class _FlowingParagraphViewState extends ConsumerState<FlowingParagraphView> {
  late List<TapGestureRecognizer> _recognizers;

  @override
  void initState() {
    super.initState();
    _initRecognizers();
  }

  @override
  void didUpdateWidget(FlowingParagraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verses != widget.verses) {
      _disposeRecognizers();
      _initRecognizers();
    }
  }

  void _initRecognizers() {
    _recognizers = widget.verses.map((v) {
      return TapGestureRecognizer()..onTap = () => widget.onVerseTap(v.verse);
    }).toList();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
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

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spans = widget.verses.asMap().entries.map((entry) {
      final index = entry.key;
      final verse = entry.value;
      final isSelected = widget.selectedVerses.contains(verse.verse);
      final highlightHex = widget.savedHighlights[verse.verse];
      final highlightColor = highlightHex != null
          ? Color(int.parse(highlightHex.replaceFirst('#', '0xFF')))
          : null;

      final bgColor = isSelected
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.6)
          : highlightColor?.withValues(alpha: 0.4);
      final recognizer = _recognizers[index];
      
      final verseSubheadings = widget.subheadings[verse.verse] ?? [];
      List<InlineSpan> subheadingSpans = [];
      for (final sh in verseSubheadings) {
        subheadingSpans.add(const TextSpan(text: '\n\n'));
        subheadingSpans.add(
          TextSpan(
            text: sh,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
        subheadingSpans.add(const TextSpan(text: '\n'));
      }

      final verseNumberSpan = TextSpan(
        text: '${verse.verse} ',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          backgroundColor: bgColor,
        ),
        recognizer: recognizer,
      );

      final verseSpans = buildVerseSpans(
        context: context,
        verse: verse,
        bgColor: bgColor,
        onVerseTap: widget.onVerseTap,
        onFootnoteTap: widget.onFootnoteTap,
        onWordRightClick: _openDictionary,
        verseNumberSpan: verseNumberSpan,
      );

      return TextSpan(
        children: [
          ...subheadingSpans,
          ...verseSpans,
        ],
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 32.0,
            ),
            child: Text.rich(TextSpan(children: spans)),
          ),
          if (widget.showFooter) const ChapterNavigationFooter(),
        ],
      ),
    );
  }
}
