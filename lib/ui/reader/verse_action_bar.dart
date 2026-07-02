import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/highlight_palette.dart';
import '../../data/importer/mybible_verse_parser.dart';
import '../../domain/scripture/verse_share_format.dart';
import '../../theme/app_themes.dart';
import '../../domain/harmony/gospel_harmony.dart';
import 'note_editor.dart';
import 'compare_panel.dart';
import 'topics_panel.dart';
import 'harmony_panel.dart';
import 'verse_image_card.dart';
import '../tags/tag_editor_dialog.dart';
import '../common/breakpoints.dart';

/// The selected verses gathered for copy/share, with text already cleaned of
/// inline markup (see [[verse-textcontent-has-markup]]).
typedef _Selection = ({
  String book,
  int chapter,
  List<int> numbers,
  List<ShareVerse> verses,
  String? abbreviation,
});

/// Reads the current verse selection and the primary version's verse text,
/// returning null when nothing usable is selected.
_Selection? _collectSelection(WidgetRef ref) {
  final versesMap = ref.read(parallelVersesProvider).value;
  if (versesMap == null || versesMap.isEmpty) return null;
  final verses = versesMap.values.first;

  final selected = ref.read(selectedVersesProvider).toList()..sort();
  final selectedModels =
      verses.where((v) => selected.contains(v.verse)).toList()
        ..sort((a, b) => a.verse.compareTo(b.verse));
  if (selectedModels.isEmpty) return null;

  final parser = MyBibleVerseParser();
  final shareVerses = <ShareVerse>[
    for (final v in selectedModels)
      (
        number: v.verse,
        text: parser
            .parseVerse(v.textContent)
            .map((s) => s.text)
            .join('')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
      ),
  ];

  return (
    book: ref.read(selectedBookNameProvider),
    chapter: ref.read(selectedChapterProvider),
    numbers: selected,
    verses: shareVerses,
    abbreviation: ref.read(primaryVersionAbbreviationProvider),
  );
}

class VerseActionBar extends ConsumerWidget {
  const VerseActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedVerses = ref.watch(selectedVersesProvider);
    if (selectedVerses.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    // Use a normal elevated surface (not inverseSurface, which is deliberately
    // a contrasting light tone in dark mode) so the floating bar matches the
    // surrounding theme in both light and dark; elevation provides separation.
    final barColor = theme.colorScheme.surfaceContainerHighest;
    final onBarColor = theme.colorScheme.onSurface;

    // On phones the labeled actions make the row too wide, so FittedBox would
    // shrink the whole bar (and its touch targets) below a usable size. Drop
    // the captions and tighten the swatches so the single row fits at close to
    // its natural size, keeping taps comfortable.
    final compact = context.isPhone;
    final swatchSize = compact ? 36.0 : 40.0;

    final swatches = [
      for (final s in highlightSlots)
        _ColorSwatch(
          // Show the colour as the active theme renders it, so the picker
          // matches what a highlight will look like.
          color: resolveHighlightDisplayColor(context, s.storedHex),
          hex: s.storedHex,
          name: s.name,
          size: swatchSize,
        ),
      _ClearHighlightSwatch(size: swatchSize),
    ];

    final actions = _buildActions(context, ref, onBarColor, showLabels: !compact);

    // On phones the swatches + actions don't fit comfortably on one line, so
    // FittedBox would shrink them below a usable size. Stack the highlight
    // swatches and the actions onto two centered rows instead. Tablets and
    // desktops keep everything on a single line with a divider between.
    final Widget content = compact
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: swatches,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final a in actions) ...[a, const SizedBox(width: 4)],
                ],
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...swatches,
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: onBarColor.withValues(alpha: 0.24)),
              const SizedBox(width: 8),
              for (final a in actions) ...[a, const SizedBox(width: 4)],
            ],
          );

    // FittedBox(scaleDown) keeps the bar centered at its natural size when it
    // fits the reader pane, gently scaling it down (never overflowing) when the
    // pane is narrower than the content.
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

  /// True when every currently-selected verse already carries a ribbon, so the
  /// action shows a "filled" icon that will remove rather than add.
  bool _allSelectedRibboned(WidgetRef ref) {
    final selected = ref.watch(selectedVersesProvider);
    if (selected.isEmpty) return false;
    final ribboned = ref
        .watch(chapterVersesWithRibbonsFamilyProvider((
          bookName: ref.watch(selectedBookNameProvider),
          chapter: ref.watch(selectedChapterProvider),
        )))
        .value ??
        const <int>{};
    return selected.every(ribboned.contains);
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
                // Filled when every selected verse already carries a ribbon, so
                // a single tap communicates whether it will add or remove.
                icon: _allSelectedRibboned(ref)
                    ? Icons.bookmark
                    : Icons.bookmark_add_outlined,
                label: 'Ribbon',
                color: onBarColor,
                showLabel: showLabels,
                onTap: () async {
                  final selected = ref.read(selectedVersesProvider).toList()..sort();
                  if (selected.isEmpty) return;
                  HapticFeedback.selectionClick();
                  final action = ref.read(bookmarkActionProvider);
                  // Add ribbons to any selected verse that lacks one; only
                  // remove when every selected verse already has one. This keeps
                  // a mixed selection (e.g. an already-ribboned verse still
                  // selected from navigation) from silently un-ribboning it.
                  final ribboned = ref
                          .read(chapterVersesWithRibbonsFamilyProvider((
                            bookName: ref.read(selectedBookNameProvider),
                            chapter: ref.read(selectedChapterProvider),
                          )))
                          .value ??
                      const <int>{};
                  final removing = selected.every(ribboned.contains);
                  for (final verse in selected) {
                    if (removing) {
                      await action.removeBookmark(verse);
                    } else {
                      await action.addBookmark(verse);
                    }
                  }
                  ref.read(selectedVersesProvider.notifier).clear();
                  if (context.mounted) {
                    final plural = selected.length > 1;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          removing
                              ? (plural ? 'Ribbons removed' : 'Ribbon removed')
                              : (plural ? 'Ribbons added' : 'Ribbon added'),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
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
              // Only offered in the four Gospels — the harmony has no events
              // elsewhere, so the action would always come up empty.
              if (GospelHarmony.isGospel(ref.watch(selectedBookNameProvider)))
                _ActionIcon(
                  icon: Icons.auto_stories,
                  label: 'Parallels',
                  color: onBarColor,
                  showLabel: showLabels,
                  onTap: () {
                    final selected = ref.read(selectedVersesProvider).toList()
                      ..sort();
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
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => HarmonyForVerseSheet(
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
                  final sel = _collectSelection(ref);
                  if (sel == null) return;
                  final format = ref.read(verseShareFormatProvider);
                  final text = VerseShareFormatter.format(
                    bookName: sel.book,
                    chapter: sel.chapter,
                    verses: sel.verses,
                    versionAbbreviation: sel.abbreviation,
                    format: format,
                  );
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  }
                  ref.read(selectedVersesProvider.notifier).clear();
                },
              ),
              _ActionIcon(
                icon: Icons.ios_share,
                label: 'Share',
                color: onBarColor,
                showLabel: showLabels,
                onTap: () => _showShareSheet(context, ref),
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

  /// iPad/macOS popovers need an anchor rectangle for the share sheet.
  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _showShareSheet(BuildContext context, WidgetRef ref) {
    final origin = _shareOrigin(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_snippet_outlined),
                title: const Text('Share text'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _shareText(ref, origin);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Share as image'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _shareImage(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareText(WidgetRef ref, Rect? origin) async {
    final sel = _collectSelection(ref);
    if (sel == null) return;
    final format = ref.read(verseShareFormatProvider);
    final text = VerseShareFormatter.format(
      bookName: sel.book,
      chapter: sel.chapter,
      verses: sel.verses,
      versionAbbreviation: sel.abbreviation,
      format: format,
    );
    final subject = VerseShareFormatter.reference(
      bookName: sel.book,
      chapter: sel.chapter,
      verseNumbers: sel.numbers,
    );
    await SharePlus.instance.share(
      ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
    );
    ref.read(selectedVersesProvider.notifier).clear();
  }

  void _shareImage(BuildContext context, WidgetRef ref) {
    final sel = _collectSelection(ref);
    if (sel == null) return;
    // The image always cites the version (when known) and flows the verse text
    // into a single quotable block, independent of the text-format preference.
    final reference = VerseShareFormatter.reference(
      bookName: sel.book,
      chapter: sel.chapter,
      verseNumbers: sel.numbers,
      versionAbbreviation: sel.abbreviation,
    );
    final body = sel.verses.map((v) => v.text).join(' ');
    ref.read(selectedVersesProvider.notifier).clear();
    showDialog<void>(
      context: context,
      builder: (_) => VerseImageShareDialog(reference: reference, verseText: body),
    );
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.format_color_reset,
                    size: 14, color: theme.colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
