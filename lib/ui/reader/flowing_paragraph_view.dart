import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../data/content_store.dart';
import 'chapter_navigation_footer.dart';
import 'dictionary_panel.dart';
import 'verse_text_builder.dart';
import '../../app/reader_state.dart';
import '../common/breakpoints.dart';

class FlowingParagraphView extends ConsumerStatefulWidget {
  final List<Verse> verses;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final Set<int> versesWithNotes;
  final Set<int> versesWithTags;
  final ValueChanged<int> onVerseTap;
  final ValueChanged<int>? onFootnoteTap;
  final ValueChanged<String>? onStrongTap;
  final bool showStrongNumbers;
  final bool showFooter;
  final Map<int, List<String>> subheadings;
  final String? searchQuery;
  final Widget? headerWidget;

  const FlowingParagraphView({
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
    this.showFooter = true,
    this.subheadings = const {},
    this.searchQuery,
    this.headerWidget,
  });

  @override
  ConsumerState<FlowingParagraphView> createState() =>
      _FlowingParagraphViewState();
}

class _FlowingParagraphViewState extends ConsumerState<FlowingParagraphView> {
  late List<TapGestureRecognizer> _recognizers;
  // Per-span tap recognizers created by buildVerseSpans (one per word and per
  // punctuation run). These are rebuilt on every build(), so the previous
  // batch must be disposed to avoid leaking recognizers/timers.
  final List<GestureRecognizer> _spanRecognizers = [];
  final Map<int, GlobalKey> _verseKeys = {};

  @override
  void initState() {
    super.initState();
    _initRecognizers();
    for (var v in widget.verses) {
      _verseKeys[v.verse] = GlobalKey();
    }
    _checkScrollTarget();
  }

  @override
  void didUpdateWidget(FlowingParagraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verses != widget.verses) {
      _disposeRecognizers();
      _initRecognizers();
      _verseKeys.clear();
      for (var v in widget.verses) {
        _verseKeys[v.verse] = GlobalKey();
      }
    }
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
        final key = _verseKeys[targetVerse];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.2,
          );
          ref.read(targetVerseToScrollProvider.notifier).set(null);
        }
      }
    });
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

  void _disposeSpanRecognizers() {
    for (final r in _spanRecognizers) {
      r.dispose();
    }
    _spanRecognizers.clear();
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

  @override
  void dispose() {
    _disposeRecognizers();
    _disposeSpanRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ActiveTool>(activeToolProvider, (previous, next) {
      if (previous == ActiveTool.none && next != ActiveTool.none) {
        if (widget.selectedVerses.isNotEmpty) {
          final targetVerse = widget.selectedVerses.first;
          final key = _verseKeys[targetVerse];
          if (key != null && key.currentContext != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Scrollable.ensureVisible(
                key.currentContext!,
                duration: const Duration(milliseconds: 300),
                alignment: 0.2,
              );
            });
          }
        }
      }
    });

    // Dispose the previous frame's per-span recognizers before building fresh
    // ones; otherwise every rebuild (selection, scroll target, theme) leaks a
    // recognizer for every word on screen.
    _disposeSpanRecognizers();
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
        children: [
          WidgetSpan(
            child: SizedBox(key: _verseKeys[verse.verse], width: 0, height: 0),
          ),
          TextSpan(
            text: '${verse.verse} ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              // Bump relative to the (delta-applied) label size so verse
              // numbers stay legible yet still track the user's font setting.
              fontSize:
                  (Theme.of(context).textTheme.labelSmall?.fontSize ?? 11) + 2,
              backgroundColor: bgColor,
            ),
            recognizer: recognizer,
          ),
        ],
      );

      final verseSpans = buildVerseSpans(
        context: context,
        verse: verse,
        bgColor: bgColor,
        onVerseTap: widget.onVerseTap,
        onFootnoteTap: widget.onFootnoteTap,
        onStrongTap: widget.onStrongTap,
        showStrongNumbers: widget.showStrongNumbers,
        onWordRightClick: _openDictionary,
        verseNumberSpan: verseNumberSpan,
        ignoreLeadingBreaks: verseSubheadings.isNotEmpty,
        searchQuery: widget.searchQuery,
        recognizers: _spanRecognizers,
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
          if (widget.headerWidget != null) widget.headerWidget!,
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
