import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../data/content_store.dart';
import '../../data/logging.dart';
import '../../data/mybible_book_map.dart';
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
    int footnoteCount = 0;
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
        final footnoteText = seg.footnoteText;

        // Some modules (e.g. the AV "KJV with cross references") store footnote
        // markers whose body is only a bracketed index like "[1]" — a call-out
        // into a cross-reference apparatus that wasn't imported. There's no
        // readable note behind them, so a marker would just open a useless
        // "[1]" popup. Drop any footnote whose body carries no letters.
        if (footnoteText == null ||
            !RegExp(r'\p{L}', unicode: true).hasMatch(footnoteText)) {
          continue;
        }

        // A quiet, link-coloured superscript reference rather than a heavy
        // filled chip — the old solid box competed with the verse text and
        // read like a tappable verse number / button. The raised baseline and
        // lighter weight keep it distinct from the bold, baseline verse number.
        //
        // Crucially we render a compact marker, NOT the footnote body itself —
        // some modules (e.g. the CrossWire KJV) carry very long notes, and
        // dumping the whole body inline made verses hard to read. The full text
        // is shown on tap.
        //
        // Conventional footnote marks rather than a number: numbering can't be
        // chapter-continuous here (buildVerseSpans runs per verse, and the list
        // builds verses lazily/out of order), so a per-verse number would just
        // render "1" on almost every verse. Marks cycle within a verse and read
        // as footnote indicators.
        const marks = ['*', '†', '‡', '§'];
        final mark = marks[footnoteCount % marks.length];
        footnoteCount++;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: GestureDetector(
              onTap: () => _showFootnote(context, footnoteText),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                // Small inset preserves a comfortable tap target without a box.
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Text(
                  mark,
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

/// Shows a footnote's full text in a modal sheet. The inline marker stays a
/// compact superscript mark so long notes (common in the CrossWire KJV) don't
/// clutter the verse; the body lives here, behind a tap. Cross-reference
/// footnotes carry `{book:chapter:verse|label}` tokens (see
/// `renderMyBibleCrossRef`) that render as tappable links to the verse.
void _showFootnote(BuildContext context, String text) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _FootnoteSheet(text: text),
  );
}

/// Matches a cross-reference token `{book:chapter:verse|label}` emitted by
/// `renderMyBibleCrossRef`. The label runs to the closing brace, so it may
/// contain spaces, colons, and hyphens (e.g. "JHN 1:1-3").
final RegExp _footnoteRefToken = RegExp(r'\{(\d+):(\d+):(\d+)\|([^}]*)\}');

class _FootnoteSheet extends ConsumerStatefulWidget {
  final String text;
  const _FootnoteSheet({required this.text});

  @override
  ConsumerState<_FootnoteSheet> createState() => _FootnoteSheetState();
}

class _FootnoteSheetState extends ConsumerState<_FootnoteSheet> {
  // Span tap recognizers must outlive build but be disposed with the sheet.
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _goToReference(int bookNumber, int chapter, int verse) {
    final bookName = mybibleBookMap[bookNumber];
    if (bookName == null) return;

    // Apply the navigation synchronously so the verse list scrolls to the
    // target the same way other in-app reference links do. Then close the
    // sheet on the next frame: popping in the same gesture relayouts the
    // reader while these providers are still dirty, which can remount
    // ReaderScreen mid-layout and throw "setState() called during build".
    ref.read(selectedBookNameProvider.notifier).set(bookName);
    ref.read(selectedChapterProvider.notifier).set(chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(verse);
    ref.read(selectedVersesProvider.notifier).clear();
    ref.read(selectedVersesProvider.notifier).toggle(verse);
    ref.read(navigationControllerProvider).recordHistory(verse: verse);

    final navigator = Navigator.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.canPop()) navigator.pop();
    });
  }

  List<InlineSpan> _buildSpans(BuildContext context) {
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _footnoteRefToken.allMatches(widget.text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: widget.text.substring(last, m.start)));
      }
      final book = int.parse(m.group(1)!);
      final chapter = int.parse(m.group(2)!);
      final verse = int.parse(m.group(3)!);
      final label = m.group(4) ?? '';
      if (mybibleBookMap.containsKey(book)) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _goToReference(book, chapter, verse);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(text: label, style: linkStyle, recognizer: recognizer),
        );
      } else {
        // Unknown book number: show the label but don't pretend it's tappable.
        spans.add(TextSpan(text: label));
      }
      last = m.end;
    }
    if (last < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(last)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt each build, so clear stale recognizers first to avoid leaks.
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Footnote',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              SelectableText.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                  children: _buildSpans(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
