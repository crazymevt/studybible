import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../domain/importer/mybible_verse_parser.dart';
import 'note_editor.dart';
import 'cross_reference_panel.dart';
import 'commentary_panel.dart';
import 'compare_panel.dart';
import '../tags/tag_editor_dialog.dart';

class VerseActionBar extends ConsumerWidget {
  const VerseActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedVerses = ref.watch(selectedVersesProvider);
    if (selectedVerses.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 12.0,
      color: const Color(0xFF2D2B3B),
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ColorSwatch(color: Color(0xFFFBE083), hex: '#FBE083'),
              const SizedBox(width: 8),
              const _ColorSwatch(color: Color(0xFF98E2C6), hex: '#98E2C6'),
              const SizedBox(width: 8),
              const _ColorSwatch(color: Color(0xFFB5E2FA), hex: '#B5E2FA'),
              const SizedBox(width: 8),
              const _ColorSwatch(color: Color(0xFFF4A8C4), hex: '#F4A8C4'),
              const SizedBox(width: 8),
              const _ClearHighlightSwatch(),
              const SizedBox(width: 16),
              Container(width: 1, height: 24, color: Colors.white24),
              const SizedBox(width: 16),
              _ActionIcon(
                icon: Icons.edit_note,
                label: 'Add Note',
                onTap: () {
                  final selected = ref.read(selectedVersesProvider);
                  showDialog(
                    context: context,
                    builder: (_) => NoteEditorDialog(verses: selected),
                  );
                  ref.read(selectedVersesProvider.notifier).clear();
                },
              ),
              const SizedBox(width: 12),
              _ActionIcon(
                icon: Icons.label,
                label: 'Tag',
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
              const SizedBox(width: 12),
              _ActionIcon(
                icon: Icons.compare_arrows,
                label: 'Cross-Reference',
                onTap: () {
                  if (MediaQuery.sizeOf(context).width > 800) {
                    ref
                        .read(activeToolProvider.notifier)
                        .setTool(ActiveTool.crossReference);
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
                        child: const CrossReferencePanel(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              _ActionIcon(
                icon: Icons.menu_book,
                label: 'Commentary',
                onTap: () {
                  if (MediaQuery.sizeOf(context).width > 800) {
                    ref
                        .read(activeToolProvider.notifier)
                        .setTool(ActiveTool.commentaries);
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
                        child: const CommentaryPanel(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              _ActionIcon(
                icon: Icons.difference,
                label: 'Compare',
                onTap: () {
                  if (MediaQuery.sizeOf(context).width > 800) {
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
              const SizedBox(width: 12),
              _ActionIcon(
                icon: Icons.copy,
                label: 'Copy',
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
              const SizedBox(width: 12),
              _ActionIcon(
                icon: Icons.close,
                label: 'Deselect',
                onTap: () => ref.read(selectedVersesProvider.notifier).clear(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends ConsumerWidget {
  final Color color;
  final String hex;

  const _ColorSwatch({required this.color, required this.hex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final selected = ref.read(selectedVersesProvider);
        for (final verse in selected) {
          await ref.read(highlightActionProvider).applyHighlight(verse, hex);
        }
        ref.read(selectedVersesProvider.notifier).clear();
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ClearHighlightSwatch extends ConsumerWidget {
  const _ClearHighlightSwatch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Clear Highlight',
      child: GestureDetector(
        onTap: () async {
          final selected = ref.read(selectedVersesProvider);
          for (final verse in selected) {
            await ref.read(highlightActionProvider).clearHighlight(verse);
          }
          ref.read(selectedVersesProvider.notifier).clear();
        },
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.format_color_reset, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
