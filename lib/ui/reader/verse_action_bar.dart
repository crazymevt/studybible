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

    final swatches = [
      const _ColorSwatch(color: Color(0xFFFBE083), hex: '#FBE083', name: 'Yellow'),
      const _ColorSwatch(color: Color(0xFF98E2C6), hex: '#98E2C6', name: 'Green'),
      const _ColorSwatch(color: Color(0xFFB5E2FA), hex: '#B5E2FA', name: 'Blue'),
      const _ColorSwatch(color: Color(0xFFF4A8C4), hex: '#F4A8C4', name: 'Pink'),
      const _ClearHighlightSwatch(),
    ];

    final actions = _buildActions(context, ref, onBarColor);

    // Stack swatches above actions, each in a Wrap, so the bar adapts to the
    // width actually available (the reader pane, not the whole window) and
    // never overflows or scrolls actions off-screen where they'd be
    // undiscoverable.
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: swatches,
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: onBarColor.withValues(alpha: 0.24)),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: actions,
        ),
      ],
    );

    return Material(
      elevation: 12.0,
      color: barColor,
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 32,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: content,
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref, Color onBarColor) {
    return [
              _ActionIcon(
                icon: Icons.edit_note,
                label: 'Add Note',
                color: onBarColor,
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
                icon: Icons.copy,
                label: 'Copy',
                color: onBarColor,
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
                onTap: () => ref.read(selectedVersesProvider.notifier).clear(),
              ),
    ];
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
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
        ),
      ),
    );
  }
}

class _ColorSwatch extends ConsumerWidget {
  final Color color;
  final String hex;
  final String name;

  const _ColorSwatch({required this.color, required this.hex, required this.name});

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
          // 40x40 hit target around the 24px visual swatch.
          child: SizedBox(
            width: 40,
            height: 40,
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
  const _ClearHighlightSwatch();

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
            width: 40,
            height: 40,
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
