import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../data/content_store.dart';
import '../../data/logging.dart';
import '../../theme/app_themes.dart';
import '../../data/models/verse_segment.dart';

List<InlineSpan> buildVerseSpans({
  required BuildContext context,
  required Verse verse,
  required Color? bgColor,
  required Function(int) onVerseTap,
  required Function(String, Offset) onWordRightClick,
  Function(int)? onFootnoteTap,
  Function(String)? onStrongTap,
  bool showStrongNumbers = false,
  InlineSpan? verseNumberSpan,
  bool ignoreLeadingBreaks = false,
  String? searchQuery,
  List<GestureRecognizer>? recognizers,
}) {
  final spans = <InlineSpan>[];
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final customColors = Theme.of(context).extension<CustomAppColors>();
  final jesusWordsColor = customColors?.jesusWordsColor ?? (isDark ? Colors.red.shade300 : Colors.red.shade700);
  final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
    height: 1.8,
    backgroundColor: bgColor,
  );
  
  if (verse.segments.isEmpty || verse.segments == '[]') {
    if (verseNumberSpan != null) spans.add(verseNumberSpan);
    final text = ignoreLeadingBreaks ? '${verse.textContent.trimLeft()} ' : '${verse.textContent} ';
    spans.addAll(_buildHighlightedSpans(
      text,
      bodyStyle,
      onVerseTap: () => onVerseTap(verse.verse),
      onWordRightClick: onWordRightClick,
      searchQuery: searchQuery,
      context: context,
      recognizers: recognizers,
    ));
    return spans;
  }

  try {
    final List<dynamic> jsonList = jsonDecode(verse.segments);
    final segments = jsonList.map((e) => VerseSegment.fromJson(e)).toList();

    bool hasText = false;
    for (final seg in segments) {
      if (!hasText && (seg.isParagraphBreak || seg.isLineBreak)) {
        if (!ignoreLeadingBreaks) {
          if (seg.isParagraphBreak) spans.add(const TextSpan(text: '\n\n'));
          if (seg.isLineBreak) spans.add(const TextSpan(text: '\n'));
        }
        continue;
      }
      
      if (!hasText) {
        hasText = true;
        if (verseNumberSpan != null) spans.add(verseNumberSpan);
      }

      if (seg.isParagraphBreak) {
        spans.add(const TextSpan(text: '\n\n'));
      } else if (seg.isLineBreak) {
        spans.add(const TextSpan(text: '\n'));
      } else if (seg.isFootnote) {
        // A quiet, link-coloured superscript reference rather than a heavy
        // filled chip — the old solid box competed with the verse text and
        // read like a tappable verse number / button. The raised baseline and
        // lighter weight keep it distinct from the bold, baseline verse number.
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: GestureDetector(
              onTap: () {
                onFootnoteTap?.call(verse.verse);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                // Small inset preserves a comfortable tap target without a box.
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Text(
                  seg.footnoteText ?? 'f',
                  // Inherit labelSmall's size (which already tracks the user's
                  // font-size delta) rather than pinning it.
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (showStrongNumbers && seg.strongs != null && seg.strongs!.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: GestureDetector(
              onTap: () {
                onStrongTap?.call(seg.strongs!);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                margin: const EdgeInsets.only(left: 2, right: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  seg.strongs!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.8,
          backgroundColor: bgColor,
          fontStyle: seg.isItalic ? FontStyle.italic : null,
          color: seg.isJesusWords ? jesusWordsColor : null,
        );

        spans.addAll(_buildHighlightedSpans(
          seg.text,
          style,
          onVerseTap: () => onVerseTap(verse.verse),
          onWordRightClick: onWordRightClick,
          searchQuery: searchQuery,
          context: context,
          recognizers: recognizers,
        ));
      }
    }
    
    if (!hasText && verseNumberSpan != null) {
       spans.add(verseNumberSpan);
    } else if (hasText) {
      // Trailing space so the verse doesn't butt against the next verse number
      // in flowing paragraph mode (matches the non-segment branches below).
      spans.add(const TextSpan(text: ' '));
    }

    return spans;
  } catch (e, stack) {
    logError(e, stack, context: 'buildVerseSpans');
    if (verseNumberSpan != null) spans.add(verseNumberSpan);
    final text = ignoreLeadingBreaks ? '${verse.textContent.trimLeft()} ' : '${verse.textContent} ';
    spans.addAll(_buildHighlightedSpans(
      text,
      bodyStyle,
      onVerseTap: () => onVerseTap(verse.verse),
      onWordRightClick: onWordRightClick,
      searchQuery: searchQuery,
      context: context,
      recognizers: recognizers,
    ));
    return spans;
  }
}

List<InlineSpan> _buildHighlightedSpans(
  String text,
  TextStyle? style, {
  required VoidCallback onVerseTap,
  required Function(String, Offset) onWordRightClick,
  required String? searchQuery,
  required BuildContext context,
  List<GestureRecognizer>? recognizers,
}) {
  if (searchQuery == null || searchQuery.isEmpty) {
    return _buildWordSpans(text, style, onVerseTap: onVerseTap, onWordRightClick: onWordRightClick, recognizers: recognizers);
  }

  final spans = <InlineSpan>[];
  final regex = RegExp(RegExp.escape(searchQuery), caseSensitive: false);
  final matches = regex.allMatches(text);

  int lastMatchEnd = 0;
  for (final match in matches) {
    if (match.start > lastMatchEnd) {
      spans.addAll(_buildWordSpans(text.substring(lastMatchEnd, match.start), style, onVerseTap: onVerseTap, onWordRightClick: onWordRightClick, recognizers: recognizers));
    }

    final highlightStyle = style?.copyWith(
          backgroundColor: Colors.yellow.withValues(alpha: 0.5),
          color: Colors.black, // Ensure text is visible on yellow
        ) ??
        TextStyle(backgroundColor: Colors.yellow.withValues(alpha: 0.5), color: Colors.black);

    spans.addAll(_buildWordSpans(text.substring(match.start, match.end), highlightStyle, onVerseTap: onVerseTap, onWordRightClick: onWordRightClick, recognizers: recognizers));
    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < text.length) {
    spans.addAll(_buildWordSpans(text.substring(lastMatchEnd), style, onVerseTap: onVerseTap, onWordRightClick: onWordRightClick, recognizers: recognizers));
  }

  return spans;
}

List<InlineSpan> _buildWordSpans(
  String text,
  TextStyle? style, {
  required VoidCallback onVerseTap,
  required Function(String, Offset) onWordRightClick,
  List<GestureRecognizer>? recognizers,
}) {
  final spans = <InlineSpan>[];
  // Match unicode letters/numbers or non-letters/numbers
  final RegExp regex = RegExp(r'([\p{L}\p{N}\p{M}]+)|([^\p{L}\p{N}\p{M}]+)', unicode: true);
  
  for (final match in regex.allMatches(text)) {
    final segment = match.group(0)!;
    final isWord = match.group(1) != null;
    
    if (!isWord) {
      final recognizer = TapGestureRecognizer()..onTap = onVerseTap;
      recognizers?.add(recognizer);
      spans.add(
        TextSpan(
          text: segment,
          style: style,
          recognizer: recognizer,
        ),
      );
    } else {
      Timer? longPressTimer;
      bool isLongPress = false;

      final recognizer = TapGestureRecognizer()
            ..onTapDown = (details) {
              isLongPress = false;
              longPressTimer = Timer(const Duration(milliseconds: 500), () {
                isLongPress = true;
                final cleanWord = segment.toLowerCase();
                if (cleanWord.isNotEmpty) {
                  onWordRightClick(cleanWord, details.globalPosition);
                }
              });
            }
            ..onTapUp = (details) {
              longPressTimer?.cancel();
              if (!isLongPress) {
                onVerseTap();
              }
            }
            ..onTapCancel = () {
              longPressTimer?.cancel();
              isLongPress = false;
            }
            ..onSecondaryTapUp = (details) {
               final cleanWord = segment.toLowerCase();
               if (cleanWord.isNotEmpty) {
                 onWordRightClick(cleanWord, details.globalPosition);
               }
            };
      recognizers?.add(recognizer);
      spans.add(
        TextSpan(
          text: segment,
          style: style,
          recognizer: recognizer,
        ),
      );
    }
  }
  return spans;
}
