import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/user_providers.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../data/user_store.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

/// The "Ribbons" jump list: every ribbon the user has dropped, in canonical
/// book order, tap to return, swipe or trailing button to remove. A ribbon is a
/// simple single-verse placeholder (stored as a [Bookmark]); this panel is the
/// counterpart to the [HistoryPanel] and opens the same way from the reader app
/// bar.
class RibbonsPanel extends ConsumerWidget {
  const RibbonsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ribbonsAsync = ref.watch(allBookmarksProvider);
    final bookOrder = ref.watch(primaryBookOrderProvider).value ?? const {};

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
                Text(
                  'Ribbons',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () {
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: ribbonsAsync.when(
                data: (ribbons) {
                  if (ribbons.isEmpty) {
                    return const EmptyState(
                      icon: Icons.bookmark_border,
                      title: 'No ribbons yet',
                      message:
                          'Select a verse and tap Ribbon to mark a spot to return to.',
                    );
                  }

                  final sorted = [...ribbons]
                    ..sort((a, b) => _canonical(a, b, bookOrder));

                  return ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _RibbonTile(ribbon: sorted[index]),
                  );
                },
                loading: () => const SkeletonList(),
                error: (err, stack) => const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Couldn\'t load ribbons',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _canonical(Bookmark a, Bookmark b, Map<String, int> bookOrder) {
    final ao = bookOrder[a.bookName] ?? 1 << 20;
    final bo = bookOrder[b.bookName] ?? 1 << 20;
    if (ao != bo) return ao.compareTo(bo);
    if (a.chapter != b.chapter) return a.chapter.compareTo(b.chapter);
    return a.verse.compareTo(b.verse);
  }
}

/// One ribbon row. Loads its verse's text lazily (sharing the per-chapter cache
/// with the reader and search), navigates to the verse on tap, and removes the
/// ribbon on swipe or via the trailing button.
class _RibbonTile extends ConsumerWidget {
  final Bookmark ribbon;

  const _RibbonTile({required this.ribbon});

  void _goTo(WidgetRef ref, BuildContext context) {
    ref.read(selectedBookNameProvider.notifier).set(ribbon.bookName);
    ref.read(selectedChapterProvider.notifier).set(ribbon.chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(ribbon.verse);
    ref.read(selectedVersesProvider.notifier).clear();
    ref.read(selectedVersesProvider.notifier).toggle(ribbon.verse);
    ref.read(navigationControllerProvider).recordHistory(verse: ribbon.verse);

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textAsync = ref.watch(chapterVerseTextProvider(
      (bookName: ribbon.bookName, chapter: ribbon.chapter),
    ));
    final text = textAsync.value?[ribbon.verse];
    final reference = '${ribbon.bookName} ${ribbon.chapter}:${ribbon.verse}';

    return Dismissible(
      key: ValueKey(ribbon.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) =>
          ref.read(bookmarkActionProvider).deleteBookmark(ribbon.id),
      child: ListTile(
        leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
        title: Text(
          reference,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: text == null
            ? null
            : Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: text != null && text.length > 50,
        trailing: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Remove ribbon',
          onPressed: () =>
              ref.read(bookmarkActionProvider).deleteBookmark(ribbon.id),
        ),
        onTap: () => _goTo(ref, context),
      ),
    );
  }
}
