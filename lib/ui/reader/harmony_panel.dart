import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/harmony_providers.dart';
import '../../app/reader_state.dart';
import '../../data/importer/mybible_verse_parser.dart';
import '../../domain/harmony/gospel_harmony.dart';
import '../../theme/app_themes.dart';
import '../common/breakpoints.dart';
import '../common/skeleton.dart';

/// Open harmony event [eventId] in the Harmony tool: the side panel on wide
/// layouts, a bottom sheet on phones.
void openHarmonyInPanel(BuildContext context, WidgetRef ref, int eventId) {
  ref.read(selectedHarmonyEventProvider.notifier).select(eventId);
  if (context.isWideLayout) {
    ref.read(activeToolProvider.notifier).openTool(ActiveTool.harmony);
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.sizeOf(context).height * 0.85,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: const HarmonyPanel(),
      ),
    );
  }
}

/// Bottom sheet listing the harmony events whose account includes a given
/// verse (reverse lookup from the verse action bar).
class HarmonyForVerseSheet extends ConsumerWidget {
  const HarmonyForVerseSheet({
    super.key,
    required this.book,
    required this.chapter,
    required this.verse,
  });

  final String book;
  final int chapter;
  final int verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(
      harmonyEventsForVerseProvider(
        (book: book, chapter: chapter, verse: verse),
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Parallel accounts for $book $chapter:$verse',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: events.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e'),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No harmony events include this verse.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final e = list[i];
                      return ListTile(
                        dense: true,
                        title: Text(e.title),
                        subtitle: _GospelChips(event: e),
                        onTap: () {
                          Navigator.of(context).maybePop();
                          openHarmonyInPanel(context, ref, e.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Harmony of the Gospels browser: a chronological list of Gospel events, each
/// opening its parallel accounts side by side.
class HarmonyPanel extends ConsumerWidget {
  const HarmonyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEvent = ref.watch(selectedHarmonyEventProvider);
    final harmonyAsync = ref.watch(gospelHarmonyProvider);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (selectedEvent != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back to events',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => ref
                            .read(selectedHarmonyEventProvider.notifier)
                            .select(null),
                      ),
                    Text(
                      'Gospel Harmony',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () {
                    ref.read(activeToolProvider.notifier).close();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: harmonyAsync.when(
              loading: () => const SkeletonList(),
              error: (e, _) =>
                  Center(child: Text('Could not load the harmony: $e')),
              data: (harmony) => selectedEvent != null
                  ? _HarmonyEventView(
                      harmony: harmony,
                      eventId: selectedEvent,
                    )
                  : _HarmonyEventList(harmony: harmony),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four M/M/L/J badges for an event, filled for the Gospels that record it.
class _GospelChips extends StatelessWidget {
  const _GospelChips({required this.event});

  final HarmonyEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 4,
        children: [
          for (final book in harmonyGospelBooks.values)
            Builder(builder: (context) {
              final r = event.refFor(book);
              final present = r != null;
              return Tooltip(
                message: present ? r.label : 'Not in $book',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: present ? scheme.secondaryContainer : null,
                    border: present
                        ? null
                        : Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    book.substring(0, 2),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: present
                              ? scheme.onSecondaryContainer
                              : scheme.outline,
                          fontWeight: present ? FontWeight.w600 : null,
                        ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _HarmonyEventList extends ConsumerWidget {
  const _HarmonyEventList({required this.harmony});

  final GospelHarmony harmony;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bookName = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final currentEvents = GospelHarmony.isGospel(bookName)
        ? harmony.eventsFor(bookName, chapter)
        : const <HarmonyEvent>[];

    final rows = <Widget>[];
    if (currentEvents.isNotEmpty) {
      rows.add(_SectionHeader(title: 'In $bookName $chapter'));
      for (final e in currentEvents) {
        rows.add(_EventTile(event: e, highlighted: true));
      }
    }
    for (final section in harmony.sections) {
      rows.add(_SectionHeader(title: section.title));
      for (final e in section.events) {
        rows.add(_EventTile(event: e));
      }
    }
    rows.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Text(
          harmony.attribution,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );

    return ListView(children: rows);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event, this.highlighted = false});

  final HarmonyEvent event;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      tileColor: highlighted
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      title: Text(event.title),
      subtitle: _GospelChips(event: event),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () =>
          ref.read(selectedHarmonyEventProvider.notifier).select(event.id),
    );
  }
}

/// One event's parallel accounts, each rendered in the primary version with a
/// header that jumps the reader to the passage.
class _HarmonyEventView extends ConsumerWidget {
  const _HarmonyEventView({required this.harmony, required this.eventId});

  final GospelHarmony harmony;
  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = harmony.eventById(eventId);
    if (event == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Text(
            event.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            event.sectionTitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        for (final r in event.refs)
          _AccountCard(eventId: event.id, harmonyRef: r),
      ],
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.eventId, required this.harmonyRef});

  final int eventId;
  final HarmonyRef harmonyRef;

  void _goToPassage(BuildContext context, WidgetRef ref) {
    ref.read(selectedBookNameProvider.notifier).set(harmonyRef.book);
    ref.read(selectedChapterProvider.notifier).set(harmonyRef.startChapter);
    ref
        .read(targetVerseToScrollProvider.notifier)
        .set(harmonyRef.startVerse);
    ref.read(selectedVersesProvider.notifier).clear();
    ref
        .read(navigationControllerProvider)
        .recordHistory(verse: harmonyRef.startVerse);
    ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
    if (MediaQuery.sizeOf(context).width <= Breakpoints.compact) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(
      harmonyPassageProvider((eventId: eventId, book: harmonyRef.book)),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customColors = theme.extension<CustomAppColors>();
    final jesusWordsColor = customColors?.jesusWordsColor ??
        (isDark ? Colors.red.shade300 : Colors.red.shade700);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    harmonyRef.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu_book, size: 20),
                  tooltip: 'Read in context',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _goToPassage(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 4),
            versesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Text('Error: $e'),
              data: (verses) {
                if (verses.isEmpty) {
                  return Text(
                    'Passage not available in the current version.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  );
                }
                final parser = MyBibleVerseParser();
                final spans = <InlineSpan>[];
                final spansChapters =
                    harmonyRef.startChapter != harmonyRef.endChapter;
                for (final v in verses) {
                  spans.add(TextSpan(
                    text: spansChapters
                        ? '${v.chapter}:${v.verse} '
                        : '${v.verse} ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ));
                  for (final s in parser.parseVerse(v.textContent)) {
                    spans.add(TextSpan(
                      text: s.text,
                      style: TextStyle(
                        fontStyle:
                            s.isItalic ? FontStyle.italic : FontStyle.normal,
                        color: s.isJesusWords ? jesusWordsColor : null,
                      ),
                    ));
                  }
                  spans.add(const TextSpan(text: ' '));
                }
                return SelectableText.rich(
                  TextSpan(children: spans),
                  style: const TextStyle(fontSize: 15, height: 1.5),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
