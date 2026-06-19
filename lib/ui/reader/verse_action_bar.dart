import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../app/app_state.dart';
import 'note_editor.dart';
import 'cross_reference_panel.dart';
import 'commentary_panel.dart';

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
            const SizedBox(width: 16),
            Container(width: 1, height: 24, color: Colors.white24),
            const SizedBox(width: 16),
            _ActionIcon(
              icon: Icons.edit_note,
              label: 'Add Note',
              onTap: () {
                final selected = ref.read(selectedVersesProvider);
                final verse = selected.isNotEmpty ? selected.first : null;
                showDialog(
                  context: context,
                  builder: (_) => NoteEditorDialog(verse: verse),
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
                  ref.read(activeToolProvider.notifier).setTool(ActiveTool.crossReference);
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  ref.read(activeToolProvider.notifier).setTool(ActiveTool.commentaries);
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const CommentaryPanel(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 12),
            _ActionIcon(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () {
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

  const _ActionIcon({required this.icon, required this.label, required this.onTap});

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
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
