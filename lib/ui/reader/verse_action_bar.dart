import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../data/importer/mybible_verse_parser.dart';
import 'note_editor.dart';
import 'compare_panel.dart';
import 'topics_panel.dart';
import '../tags/tag_editor_dialog.dart';
import '../common/breakpoints.dart';

class VerseActionBar extends ConsumerWidget {
  const VerseActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedVerses = ref.watch(selectedVersesProvider);
    if (selectedVerses.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final barColor = theme.colorScheme.inverseSurface;
    final onBarColor = theme.colorScheme.onInverseSurface;

    // On phones the labeled actions make the row too wide, so FittedBox would
    // shrink the whole bar (and its touch targets) below a usable size. Drop
    // the captions and tighten the swatches so the single row fits at close to
    // its natural size, keeping taps comfortable.
    final compact = context.isPhone;
    final swatchSize = compact ? 36.0 : 40.0;

    final swatches = [
      _ColorSwatch(color: const Color(0xFFFBE083), hex: '#FBE083', name: 'Yellow', size: swatchSize),
      _ColorSwatch(color: const Color(0xFF98E2C6), hex: '#98E2C6', name: 'Green', size: swatchSize),
      _ColorSwatch(color: const Color(0xFFB5E2FA), hex: '#B5E2FA', name: 'Blue', size: swatchSize),
      _ColorSwatch(color: const Color(0xFFF4A8C4), hex: '#F4A8C4', name: 'Pink', size: swatchSize),
      _ClearHighlightSwatch(size: swatchSize),
    ];

    final actions = _buildActions(context, ref, onBarColor, showLabels: !compact);

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...swatches,
        const SizedBox(width: 8),
        Container(width: 1, height: 24, color: onBarColor.withValues(alpha: 0.24)),
        const SizedBox(width: 8),
        for (final a in actions) ...[a, const SizedBox(width: 4)],
      ],
    );

    // FittedBox(scaleDown) keeps the bar a single centered row: at its natural
    // size when it fits the reader pane, gently scaled down (never wrapped or
    // overflowing) when the pane is too narrow.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Material(
        elevation: 12.0,
        color: barColor,
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10.0 : 16.0, vertical: 8.0),
          child: content,
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref, Color onBarColor,
      {required bool showLabels}) {
    return [
              _ActionIcon(
                icon: Icons.edit_note,
                label: 'Add Note',
                color: onBarColor,
                showLabel: showLabels,
                onTap: () {
                  final selected = ref.read(selectedVersesProvider);
                  showDialog(
                    context: context,
                    builder: (_) => NoteEditorDialog(verses: selected),
                  );
                  ref.read(selectedVersesProvider.notifier).clear();
                },
              ),
              _ActionIcon(
                icon: Icons.label,
                label: 'Tag',
                color: onBarColor,
                showLabel: showLabels,
                onTap: () {
                  final selected = ref.read(selectedVersesProvider).toList()..sort();
                  if (selected.isEmpty) return;
                  
                  final book = ref.read(selectedBookNameProvider);
                  final chapter = ref.read(selectedChapterProvider);
                  final verse = selected.first;

                  showDialog(
                    context: context,
                    builder: (_) => TagEditorDialog(
                      entityId: 'Verse:$book|$chapter|$verse',
                      entityType: 'verse',
                    ),
                  );
                  ref.read(selectedVersesProvider.notifier).clear();
                },
              ),

              _ActionIcon(
                icon: Icons.difference,
                label: 'Compare',
                color: onBarColor,
                showLabel: showLabels,
                onTap: () {
                  if (context.isWideLayout) {
                    ref
                        .read(activeToolProvider.notifier)
                        .setTool(ActiveTool.compare);
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
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: const ComparePanel(),
                      ),
                    );
                  }
                },
              ),
              _ActionIcon(
                icon: Icons.topic,
                label: 'Topics',
                color: onBarColor,
                showLabel: showLabels,
                onTap: () {
                  final selected = ref.read(selectedVersesProvider).toList()..sort();
                  if (selected.isEmpty) return;
                  final book = ref.read(selectedBookNameProvider);
                  final chapter = ref.read(selectedChapterProvider);
                  final verse = selected.first;
                  ref.read(selectedVersesProvider.notifier).clear();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => TopicsForVerseSheet(
                      book: book,
                      chapter: chapter,
                      verse: verse,
                    ),
                  );
                },
              ),
              _ActionIcon(
                icon: Icons.copy,
                label: 'Copy',
                color: onBarColor,
                showLabel: showLabels,
                onTap: () async {
                  final versesMap = ref.read(parallelVersesProvider).value;
                  if (versesMap == null || versesMap.isEmpty) return;
                  final verses = versesMap.values.first;

                  final selected = ref.read(selectedVersesProvider).toList()..sort();
                  final selectedVerseModels = verses.where((v) => selected.contains(v.verse)).toList();
                  if (selectedVerseModels.isEmpty) return;

                  final book = ref.read(selectedBookNameProvider);
                  final chapter = ref.read(selectedChapterProvider);
                  
                  String formatVerseList(List<int> verses) {
                    if (verses.isEmpty) return '';
                    final parts = <String>[];
                    int start = verses.first;
                    int end = verses.first;

                    for (int i = 1; i < verses.length; i++) {
                      if (verses[i] == end + 1) {
                        end = verses[i];
                      } else {
                        parts.add(start == end ? '$start' : '$start-$end');
                        start = verses[i];
                        end = verses[i];
                      }
                    }
                    parts.add(start == end ? '$start' : '$start-$end');
                    return parts.join(', ');
                  }

                  final verseNumbers = formatVerseList(selected);

                  final buffer = StringBuffer();
                  buffer.writeln('$book $chapter:$verseNumbers');

                  final parser = MyBibleVerseParser();
                  for (final v in selectedVerseModels) {
                    final cleanText = parser.parseVerse(v.textContent).map((s) => s.text).join('').replaceAll(RegExp(r'\s+'), ' ').trim();
                    buffer.writeln('${v.verse} $cleanText');
                  }

                  await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  }
                  ref.read(selectedVersesProvider.notifier).clear();
                },
              ),
              _ActionIcon(
                icon: Icons.close,
                label: 'Deselect',
                color: onBarColor,
                showLabel: showLabels,
                onTap: () => ref.read(selectedVersesProvider.notifier).clear(),
              ),
    ];
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool showLabel;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    // Icon-only mode keeps a generous touch target (40px) while staying narrow.
    final iconButton = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(showLabel ? 8 : 20),
      child: showLabel
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
                  ),
                ],
              ),
            )
          : SizedBox(
              width: 40,
              height: 40,
              child: Center(child: Icon(icon, color: color, size: 22)),
            ),
    );
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: iconButton,
      ),
    );
  }
}

class _ColorSwatch extends ConsumerWidget {
  final Color color;
  final String hex;
  final String name;
  final double size;

  const _ColorSwatch({
    required this.color,
    required this.hex,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: '$name highlight',
      child: Semantics(
        button: true,
        label: '$name highlight',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            HapticFeedback.selectionClick();
            final selected = ref.read(selectedVersesProvider);
            for (final verse in selected) {
              await ref.read(highlightActionProvider).applyHighlight(verse, hex);
            }
            ref.read(selectedVersesProvider.notifier).clear();
          },
          // Hit target around the 24px visual swatch.
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearHighlightSwatch extends ConsumerWidget {
  final double size;
  const _ClearHighlightSwatch({this.size = 40});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Clear highlight',
      child: Semantics(
        button: true,
        label: 'Clear highlight',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            HapticFeedback.selectionClick();
            final selected = ref.read(selectedVersesProvider);
            for (final verse in selected) {
              await ref.read(highlightActionProvider).clearHighlight(verse);
            }
            ref.read(selectedVersesProvider.notifier).clear();
          },
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onInverseSurface.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.format_color_reset,
                    size: 14, color: theme.colorScheme.onInverseSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
