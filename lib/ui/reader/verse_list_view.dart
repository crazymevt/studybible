import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/content_store.dart';
import '../../data/models/verse_segment.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';

import 'chapter_navigation_footer.dart';

class VerseListView extends ConsumerStatefulWidget {
  final List<Verse> verses;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final ValueChanged<int> onVerseTap;
  final bool showFooter;

  const VerseListView({
    super.key,
    required this.verses,
    required this.selectedVerses,
    required this.savedHighlights,
    required this.onVerseTap,
    this.showFooter = true,
  });

  @override
  ConsumerState<VerseListView> createState() => _VerseListViewState();
}

class _VerseListViewState extends ConsumerState<VerseListView> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

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
        )
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
        } else {
          spans.add(TextSpan(
            text: seg.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontStyle: seg.isItalic ? FontStyle.italic : null,
                  color: seg.isJesusWords ? Colors.red.shade700 : null,
                ),
          ));
        }
      }
      return spans;
    } catch (e) {
      return [
        TextSpan(
          text: verse.textContent,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        )
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
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
            : highlightColor?.withValues(alpha: 0.2);

        return ListTile(
          tileColor: bgColor,
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
                ..._buildVerseSpans(context, verse),
              ],
            ),
          ),
          onTap: () => widget.onVerseTap(verse.verse),
        );
      },
    );
  }
}
