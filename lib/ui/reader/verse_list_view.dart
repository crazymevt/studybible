import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/content_store.dart';
import '../../data/models/verse_segment.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';
import '../../app/app_state.dart';

import 'chapter_navigation_footer.dart';

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

  List<InlineSpan> _buildVerseSpans(BuildContext context, Verse verse) {
    if (verse.segments.isEmpty || verse.segments == '[]') {
      return [
        TextSpan(
          text: verse.textContent,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(verse.segments);
      final segments = jsonList.map((e) => VerseSegment.fromJson(e)).toList();
      final List<InlineSpan> spans = [];
      bool hasText = false;
      for (final seg in segments) {
        if (!hasText && (seg.isParagraphBreak || seg.isLineBreak)) {
          continue; // skip leading breaks
        }
        hasText = true;

        if (seg.isParagraphBreak) {
          spans.add(const TextSpan(text: '\n\n'));
        } else if (seg.isLineBreak) {
          spans.add(const TextSpan(text: '\n'));
        } else if (seg.isFootnote) {
          spans.add(
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
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: seg.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontStyle: seg.isItalic ? FontStyle.italic : null,
                color: seg.isJesusWords ? Colors.red.shade700 : null,
              ),
            ),
          );
        }
      }
      return spans;
    } catch (e) {
      return [
        TextSpan(
          text: verse.textContent,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ];
    }
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

        return Padding(
          padding: EdgeInsets.symmetric(vertical: verseSpacing / 2),
          child: ListTile(
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
        );
      },
    );
  }
}
