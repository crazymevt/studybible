import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../data/content_store.dart';
import '../../data/models/verse_segment.dart';
import '../../app/reader_state.dart';
import '../../app/app_state.dart';
import 'flowing_paragraph_view.dart';
import 'chapter_navigation_footer.dart';

class ParallelView extends ConsumerStatefulWidget {
  final Map<String, List<Verse>> versesMap;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final Set<int> versesWithNotes;
  final Set<int> versesWithTags;
  final Function(int) onVerseTap;
  final ValueChanged<int>? onFootnoteTap;
  final bool isFlowing;
  final ItemScrollController? externalScrollController;
  final ItemPositionsListener? externalPositionsListener;

  const ParallelView({
    super.key,
    required this.versesMap,
    required this.selectedVerses,
    this.versesWithNotes = const {},
    this.versesWithTags = const {},
    required this.savedHighlights,
    required this.onVerseTap,
    this.onFootnoteTap,
    this.isFlowing = false,
    this.externalScrollController,
    this.externalPositionsListener,
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
          itemScrollController.jumpTo(index: targetIndex);
          // Clear it so we don't jump again on rebuild
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
          continue;
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
                    onVerseTap: widget.onVerseTap,
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
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
            itemCount: verseNumbers.length + 1,
            itemBuilder: (context, index) {
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

              return Padding(
                padding: EdgeInsets.symmetric(vertical: verseSpacing / 2),
                child: Container(
                  color: bgColor,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: keys.map((versionId) {
                        final verses = widget.versesMap[versionId] ?? [];
                        // Find the verse or return a fallback
                        final verse = verses.firstWhere(
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

                        return Expanded(
                          child: InkWell(
                            onTap: () => widget.onVerseTap(verseNum),
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          ..._buildVerseSpans(context, verse),
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
              );
            },
          ),
        ),
      ],
    );
  }
}
