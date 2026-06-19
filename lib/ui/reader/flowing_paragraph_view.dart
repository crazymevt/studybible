import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../data/content_store.dart';
import '../../data/models/verse_segment.dart';
import 'chapter_navigation_footer.dart';

class FlowingParagraphView extends StatefulWidget {
  final List<Verse> verses;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final Set<int> versesWithNotes;
  final Set<int> versesWithTags;
  final ValueChanged<int> onVerseTap;
  final ValueChanged<int>? onFootnoteTap;
  final bool showFooter;

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
  });

  @override
  State<FlowingParagraphView> createState() => _FlowingParagraphViewState();
}

class _FlowingParagraphViewState extends State<FlowingParagraphView> {
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

      List<InlineSpan> leadingBreaks = [];
      List<InlineSpan> verseSpans;
      if (verse.segments.isEmpty || verse.segments == '[]') {
        verseSpans = [
          TextSpan(
            text: '${verse.textContent} ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.8,
              backgroundColor: bgColor,
            ),
            recognizer: recognizer,
          ),
        ];
      } else {
        try {
          final List<dynamic> jsonList = jsonDecode(verse.segments);
          final segments = jsonList
              .map((e) => VerseSegment.fromJson(e))
              .toList();
          verseSpans = [];
          bool hasText = false;
          for (final seg in segments) {
            if (!hasText && (seg.isParagraphBreak || seg.isLineBreak)) {
              if (seg.isParagraphBreak)
                leadingBreaks.add(const TextSpan(text: '\n\n'));
              if (seg.isLineBreak)
                leadingBreaks.add(const TextSpan(text: '\n'));
              continue;
            }
            hasText = true;

            if (seg.isParagraphBreak) {
              verseSpans.add(const TextSpan(text: '\n\n'));
            } else if (seg.isLineBreak) {
              verseSpans.add(const TextSpan(text: '\n'));
            } else if (seg.isFootnote) {
              verseSpans.add(
                WidgetSpan(
                  alignment: PlaceholderAlignment.top,
                  child: GestureDetector(
                    onTap: () {
                      widget.onVerseTap(verse.verse);
                      widget.onFootnoteTap?.call(verse.verse);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(left: 2, right: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        seg.footnoteText ?? 'f',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              verseSpans.add(
                TextSpan(
                  text: seg.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    backgroundColor: bgColor,
                    fontStyle: seg.isItalic ? FontStyle.italic : null,
                    color: seg.isJesusWords ? Colors.red.shade700 : null,
                  ),
                  recognizer: recognizer,
                ),
              );
            }
          }
        } catch (e) {
          verseSpans = [
            TextSpan(
              text: '${verse.textContent} ',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.8,
                backgroundColor: bgColor,
              ),
              recognizer: recognizer,
            ),
          ];
        }
      }

      return TextSpan(
        children: [
          ...leadingBreaks,
          TextSpan(
            text: '${verse.verse} ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              backgroundColor: bgColor,
            ),
            recognizer: recognizer,
          ),
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
