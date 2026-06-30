import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../data/user_store.dart';

/// The highlight swatch palette, mirroring the verse action bar, so the review
/// list can show a friendly colour name and a matching filter.
const _highlightSwatches = <({String hex, String name})>[
  (hex: '#FBE083', name: 'Yellow'),
  (hex: '#98E2C6', name: 'Green'),
  (hex: '#B5E2FA', name: 'Blue'),
  (hex: '#F4A8C4', name: 'Pink'),
];

/// How the highlights list is ordered.
enum HighlightSort {
  canonical('Bible order'),
  newest('Newest first'),
  oldest('Oldest first'),
  color('By colour');

  const HighlightSort(this.label);
  final String label;
}

Color? _parseHex(String hex) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

String _nameForHex(String hex) {
  for (final s in _highlightSwatches) {
    if (s.hex.toLowerCase() == hex.toLowerCase()) return s.name;
  }
  return 'Highlight';
}

/// A browsable, sortable, filterable list of every highlight the user has made —
/// the "where did I mark that?" view. Each row shows its verse text (loaded
/// lazily per chapter); tapping an entry jumps the reader to it.
class HighlightsPanel extends ConsumerStatefulWidget {
  const HighlightsPanel({super.key});

  @override
  ConsumerState<HighlightsPanel> createState() => _HighlightsPanelState();
}

class _HighlightsPanelState extends ConsumerState<HighlightsPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _colorFilter; // hex, or null for "all"
  String? _bookFilter; // book name, or null for "all"
  HighlightSort _sort = HighlightSort.canonical;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightsAsync = ref.watch(allHighlightsProvider);
    final bookOrder = ref.watch(primaryBookOrderProvider).value ?? const {};
    // Only resolve the aggregate text map while searching, so browsing stays lazy.
    final searchTexts = _query.isEmpty
        ? null
        : ref.watch(allHighlightTextsProvider).value;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: highlightsAsync.when(
              data: (highlights) {
                final books = _booksWithHighlights(highlights, bookOrder);
                final visible = _applyFilters(highlights, searchTexts, bookOrder);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildControls(context, books),
                    const Divider(height: 1),
                    Expanded(
                      child: visible.isEmpty
                          ? Center(
                              child: Text(
                                highlights.isEmpty
                                    ? 'No highlights yet.'
                                    : 'No highlights match your filters.',
                              ),
                            )
                          : ListView.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) => _HighlightTile(
                                highlight: visible[index],
                                onTap: _goTo,
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  const Center(child: Text('Error loading highlights')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Highlights',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(activeToolProvider.notifier).close();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, List<String> books) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search reference or text',
              border: const OutlineInputBorder(),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<HighlightSort>(
                  initialValue: _sort,
                  isDense: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Sort',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final s in HighlightSort.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (s) =>
                      setState(() => _sort = s ?? HighlightSort.canonical),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue:
                      books.contains(_bookFilter) ? _bookFilter : null,
                  isDense: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Book',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All books'),
                    ),
                    for (final b in books)
                      DropdownMenuItem(value: b, child: Text(b)),
                  ],
                  onChanged: (b) => setState(() => _bookFilter = b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _colorFilter == null,
                  onSelected: (_) => setState(() => _colorFilter = null),
                ),
                const SizedBox(width: 8),
                for (final s in _highlightSwatches) ...[
                  ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: _parseHex(s.hex)),
                    label: Text(s.name),
                    selected:
                        _colorFilter?.toLowerCase() == s.hex.toLowerCase(),
                    onSelected: (_) => setState(() => _colorFilter = s.hex),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Distinct books that have highlights, in canonical order.
  List<String> _booksWithHighlights(
    List<Highlight> highlights,
    Map<String, int> bookOrder,
  ) {
    final names = {for (final h in highlights) h.bookName}.toList()
      ..sort((a, b) {
        final ao = bookOrder[a] ?? 1 << 20;
        final bo = bookOrder[b] ?? 1 << 20;
        return ao != bo ? ao.compareTo(bo) : a.compareTo(b);
      });
    return names;
  }

  List<Highlight> _applyFilters(
    List<Highlight> highlights,
    Map<String, String>? searchTexts,
    Map<String, int> bookOrder,
  ) {
    final query = _query.toLowerCase();
    final filtered = highlights.where((h) {
      if (_colorFilter != null &&
          h.colorHex.toLowerCase() != _colorFilter!.toLowerCase()) {
        return false;
      }
      if (_bookFilter != null && h.bookName != _bookFilter) return false;
      if (query.isEmpty) return true;
      final reference = '${h.bookName} ${h.chapter}:${h.verse}'.toLowerCase();
      if (reference.contains(query)) return true;
      // Verse-text match (available once allHighlightTextsProvider resolves).
      final text = searchTexts?[
          highlightTextKey(h.bookName, h.chapter, h.verse)];
      return text != null && text.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) => _compare(a, b, bookOrder));
    return filtered;
  }

  int _compare(Highlight a, Highlight b, Map<String, int> bookOrder) {
    int canonical() {
      final ao = bookOrder[a.bookName] ?? 1 << 20;
      final bo = bookOrder[b.bookName] ?? 1 << 20;
      if (ao != bo) return ao.compareTo(bo);
      if (a.chapter != b.chapter) return a.chapter.compareTo(b.chapter);
      return a.verse.compareTo(b.verse);
    }

    switch (_sort) {
      case HighlightSort.canonical:
        return canonical();
      case HighlightSort.newest:
        return b.updatedAt.compareTo(a.updatedAt);
      case HighlightSort.oldest:
        return a.updatedAt.compareTo(b.updatedAt);
      case HighlightSort.color:
        final c = a.colorHex.compareTo(b.colorHex);
        return c != 0 ? c : canonical();
    }
  }

  void _goTo(Highlight h) {
    ref.read(selectedBookNameProvider.notifier).set(h.bookName);
    ref.read(selectedChapterProvider.notifier).set(h.chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(h.verse);
    ref.read(selectedVersesProvider.notifier).clear();
    ref.read(selectedVersesProvider.notifier).toggle(h.verse);
    ref.read(navigationControllerProvider).recordHistory(verse: h.verse);

    ref.read(activeToolProvider.notifier).close();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

/// One highlight row. Loads its chapter's verse text lazily (and shares the
/// per-chapter cache with sibling rows and with search).
class _HighlightTile extends ConsumerWidget {
  final Highlight highlight;
  final void Function(Highlight) onTap;

  const _HighlightTile({required this.highlight, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseHex(highlight.colorHex);
    final textAsync = ref.watch(chapterVerseTextProvider(
      (bookName: highlight.bookName, chapter: highlight.chapter),
    ));
    final text = textAsync.value?[highlight.verse];

    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color ?? Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
      ),
      title: Text(
        '${highlight.bookName} ${highlight.chapter}:${highlight.verse}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: text == null
          ? null
          : Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      isThreeLine: text != null && text.length > 50,
      trailing: Text(
        _nameForHex(highlight.colorHex),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      onTap: () => onTap(highlight),
    );
  }
}
