import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/content_store.dart';
import '../../data/models/verse_segment.dart';
import 'flowing_paragraph_view.dart';
import 'chapter_navigation_footer.dart';

class ParallelView extends ConsumerWidget {
  final Map<String, List<Verse>> versesMap;
  final bool isFlowing;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final ValueChanged<int> onVerseTap;

  const ParallelView({
    super.key,
    required this.versesMap,
    required this.isFlowing,
    required this.selectedVerses,
    required this.savedHighlights,
    required this.onVerseTap,
  });

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
          continue;
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

  Widget _buildHeader(BuildContext context, String versionId) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          versionId,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (versesMap.isEmpty) {
      return const Center(child: Text('No active versions.'));
    }

    final keys = versesMap.keys.toList();

    if (isFlowing) {
      // Flowing mode: independent columns
      return Row(
        children: keys.map((versionId) {
          final verses = versesMap[versionId] ?? [];
          return Expanded(
            child: Column(
              children: [
                _buildHeader(context, versionId),
                Expanded(
                  child: FlowingParagraphView(
                    verses: verses,
                    selectedVerses: selectedVerses,
                    savedHighlights: savedHighlights,
                    onVerseTap: onVerseTap,
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
    for (final verses in versesMap.values) {
      allVerseNumbers.addAll(verses.map((v) => v.verse));
    }
    final verseNumbers = allVerseNumbers.toList()..sort();

    return Column(
      children: [
        Row(
          children: keys.map((versionId) {
            return Expanded(
              child: _buildHeader(context, versionId),
            );
          }).toList(),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            itemCount: verseNumbers.length + 1,
            itemBuilder: (context, index) {
              if (index == verseNumbers.length) {
                return const ChapterNavigationFooter();
              }

              final verseNum = verseNumbers[index];
              final isSelected = selectedVerses.contains(verseNum);
              final highlightHex = savedHighlights[verseNum];
              final highlightColor = highlightHex != null 
                  ? Color(int.parse(highlightHex.replaceFirst('#', '0xFF'))) 
                  : null;

              final bgColor = isSelected
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : highlightColor?.withValues(alpha: 0.2);

              return Container(
                color: bgColor,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: keys.map((versionId) {
                      final verses = versesMap[versionId] ?? [];
                      // Find the verse or return a fallback
                      final verse = verses.firstWhere(
                        (v) => v.verse == verseNum, 
                        orElse: () => Verse(id: -1, bookId: -1, chapter: -1, verse: verseNum, textContent: '', segments: '[]')
                      );

                      return Expanded(
                        child: InkWell(
                           onTap: () => onVerseTap(verseNum),
                           child: Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                             child: verse.id == -1 
                                 ? const SizedBox.shrink() // empty cell if verse is missing in this translation
                                 : Text.rich(
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
                           ),
                        ),
                      );
                    }).toList(),
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
