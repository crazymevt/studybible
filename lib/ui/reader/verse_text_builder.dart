import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../data/content_store.dart';
import '../../data/models/verse_segment.dart';

List<InlineSpan> buildVerseSpans({
  required BuildContext context,
  required Verse verse,
  required Color? bgColor,
  required Function(int) onVerseTap,
  required Function(String, Offset) onWordRightClick,
  Function(int)? onFootnoteTap,
  InlineSpan? verseNumberSpan,
}) {
  final spans = <InlineSpan>[];
  final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
    height: 1.8,
    backgroundColor: bgColor,
  );
  
  if (verse.segments.isEmpty || verse.segments == '[]') {
    if (verseNumberSpan != null) spans.add(verseNumberSpan);
    spans.addAll(_buildWordSpans(
      '${verse.textContent} ',
      bodyStyle,
      onVerseTap: () => onVerseTap(verse.verse),
      onWordRightClick: onWordRightClick,
    ));
    return spans;
  }

  try {
    final List<dynamic> jsonList = jsonDecode(verse.segments);
    final segments = jsonList.map((e) => VerseSegment.fromJson(e)).toList();

    bool hasText = false;
    for (final seg in segments) {
      if (!hasText && (seg.isParagraphBreak || seg.isLineBreak)) {
        if (seg.isParagraphBreak) spans.add(const TextSpan(text: '\n\n'));
        if (seg.isLineBreak) spans.add(const TextSpan(text: '\n'));
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
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: GestureDetector(
              onTap: () {
                onVerseTap(verse.verse);
                onFootnoteTap?.call(verse.verse);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
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
        final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.8,
          backgroundColor: bgColor,
          fontStyle: seg.isItalic ? FontStyle.italic : null,
          color: seg.isJesusWords ? Colors.red.shade700 : null,
        );

        spans.addAll(_buildWordSpans(
          seg.text,
          style,
          onVerseTap: () => onVerseTap(verse.verse),
          onWordRightClick: onWordRightClick,
        ));
      }
    }
    
    if (!hasText && verseNumberSpan != null) {
       spans.add(verseNumberSpan);
    }
    
    return spans;
  } catch (e) {
    if (verseNumberSpan != null) spans.add(verseNumberSpan);
    spans.addAll(_buildWordSpans(
      '${verse.textContent} ',
      bodyStyle,
      onVerseTap: () => onVerseTap(verse.verse),
      onWordRightClick: onWordRightClick,
    ));
    return spans;
  }
}

List<InlineSpan> _buildWordSpans(
  String text,
  TextStyle? style, {
  required VoidCallback onVerseTap,
  required Function(String, Offset) onWordRightClick,
}) {
  final spans = <InlineSpan>[];
  // Match unicode letters/numbers or non-letters/numbers
  final RegExp regex = RegExp(r'([\p{L}\p{N}\p{M}]+)|([^\p{L}\p{N}\p{M}]+)', unicode: true);
  
  for (final match in regex.allMatches(text)) {
    final segment = match.group(0)!;
    final isWord = match.group(1) != null;
    
    if (!isWord) {
      spans.add(
        TextSpan(
          text: segment,
          style: style,
          recognizer: TapGestureRecognizer()..onTap = onVerseTap,
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: segment,
          style: style,
          recognizer: TapGestureRecognizer()
            ..onTap = onVerseTap
            ..onSecondaryTapUp = (details) {
               final cleanWord = segment.toLowerCase();
               if (cleanWord.isNotEmpty) {
                 onWordRightClick(cleanWord, details.globalPosition);
               }
            },
        ),
      );
    }
  }
  return spans;
}
