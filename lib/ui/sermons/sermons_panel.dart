import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/sermon_providers.dart';
import '../../app/tag_providers.dart';
import '../../data/user_store.dart';
import '../tags/tag_palette.dart';
import 'export_dialog.dart';
import 'sermon_editor_screen.dart';
import '../common/breakpoints.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

/// How the sermon list is ordered. "Created" uses the sermon's creation time.
enum _SermonSort { titleAsc, titleDesc, createdDesc, createdAsc }

const Map<_SermonSort, String> _sortLabels = {
  _SermonSort.titleAsc: 'Title (A–Z)',
  _SermonSort.titleDesc: 'Title (Z–A)',
  _SermonSort.createdDesc: 'Newest first',
  _SermonSort.createdAsc: 'Oldest first',
};

class SermonsPanel extends ConsumerStatefulWidget {
  const SermonsPanel({super.key});

  @override
  ConsumerState<SermonsPanel> createState() => _SermonsPanelState();
}

class _SermonsPanelState extends ConsumerState<SermonsPanel> {
  final _searchController = TextEditingController();
  String _query = '';
  _SermonSort _sort = _SermonSort.createdDesc;
  String? _activeTagId;
  String? _activeTagName;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _titleKey(Sermon s) =>
      (s.title.isEmpty ? 'untitled sermon' : s.title).toLowerCase();

  /// Filters by the search box (matches title, series, or any tag name) and the
  /// pinned tag filter, then sorts by [_sort].
  List<Sermon> _visibleSermons(
    List<Sermon> sermons,
    Map<String, List<TagData>> tagsBySermon,
  ) {
    final raw = _query.trim().toLowerCase();
    final needle = raw.startsWith('#') ? raw.substring(1) : raw;

    final filtered = sermons.where((s) {
      final tags = tagsBySermon[s.id] ?? const <TagData>[];

      if (_activeTagId != null && !tags.any((t) => t.id == _activeTagId)) {
        return false;
      }

      if (needle.isEmpty) return true;
      if (_titleKey(s).contains(needle)) return true;
      if ((s.series ?? '').toLowerCase().contains(needle)) return true;
      return tags.any((t) => t.name.toLowerCase().contains(needle));
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case _SermonSort.titleAsc:
          return _titleKey(a).compareTo(_titleKey(b));
        case _SermonSort.titleDesc:
          return _titleKey(b).compareTo(_titleKey(a));
        case _SermonSort.createdDesc:
          return b.createdAt.compareTo(a.createdAt);
        case _SermonSort.createdAsc:
          return a.createdAt.compareTo(b.createdAt);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final activeSermonId = ref.watch(selectedSermonIdProvider);
    if (activeSermonId != null) {
      return SermonEditorScreen(sermonId: activeSermonId, isFullScreen: false);
    }

    final sermonsAsync = ref.watch(allSermonsProvider);
    final tagsBySermon =
        ref.watch(sermonTagsProvider).asData?.value ??
        const <String, List<TagData>>{};

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sermons',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<_SermonSort>(
                          icon: const Icon(Icons.sort),
                          tooltip: 'Sort',
                          initialValue: _sort,
                          onSelected: (v) => setState(() => _sort = v),
                          itemBuilder: (context) => [
                            for (final entry in _sortLabels.entries)
                              CheckedPopupMenuItem(
                                value: entry.key,
                                checked: _sort == entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.file_upload),
                          tooltip: 'Export All',
                          onPressed: () {
                            sermonsAsync.whenData((sermons) {
                              if (sermons.isNotEmpty) {
                                ExportDialog.show(context, sermons);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No sermons to export.'),
                                  ),
                                );
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'New Sermon',
                          onPressed: () => _showNewSermonDialog(context, ref),
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
                  ],
                ),
                _buildSearchBar(context),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: sermonsAsync.when(
                data: (sermons) {
                  if (sermons.isEmpty) {
                    return const EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No sermons yet',
                      message: 'Tap + to start your first sermon.',
                    );
                  }
                  final visible = _visibleSermons(sermons, tagsBySermon);
                  if (visible.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off,
                      title: 'No matching sermons',
                      message:
                          'Try a different search or clear the tag filter.',
                    );
                  }
                  return ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sermon = visible[index];
                      final tags = tagsBySermon[sermon.id] ?? const <TagData>[];
                      return ListTile(
                        title: Text(
                          sermon.title.isEmpty
                              ? 'Untitled Sermon'
                              : sermon.title,
                        ),
                        subtitle: _buildSubtitle(context, sermon, tags),
                        isThreeLine: tags.isNotEmpty,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Delete Sermon',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Sermon'),
                                content: const Text(
                                  'Are you sure you want to delete this sermon?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref
                                  .read(sermonActionProvider)
                                  .deleteSermon(sermon.id);
                            }
                          },
                        ),
                        onTap: () {
                          if (MediaQuery.sizeOf(context).width >
                              Breakpoints.compact) {
                            ref
                                .read(selectedSermonIdProvider.notifier)
                                .set(sermon.id);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SermonEditorScreen(
                                  sermonId: sermon.id,
                                  isFullScreen: true,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const SkeletonList(),
                error: (e, st) => const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Couldn\'t load sermons',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search sermons or #tags…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_activeTagId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InputChip(
                avatar: const Icon(Icons.filter_alt, size: 16),
                label: Text('#${_activeTagName ?? ''}'),
                onDeleted: () => setState(() {
                  _activeTagId = null;
                  _activeTagName = null;
                }),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    Sermon sermon,
    List<TagData> tags,
  ) {
    final series = (sermon.series?.isNotEmpty ?? false)
        ? sermon.series!
        : 'No Series';
    if (tags.isEmpty) return Text(series);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(series),
          for (final tag in tags) _TagChip(tag: tag, onTap: () => _pinTag(tag)),
        ],
      ),
    );
  }

  void _pinTag(TagData tag) {
    setState(() {
      _activeTagId = tag.id;
      _activeTagName = tag.name;
    });
  }

  Future<void> _showNewSermonDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String title, String? series})>(
      context: context,
      builder: (context) => const _NewSermonDialog(),
    );
    if (result == null || !context.mounted) return;

    final sermon = await ref
        .read(sermonActionProvider)
        .createSermon(result.title, series: result.series);
    if (!context.mounted) return;

    // Open the editor only after the dialog has fully dismissed (its future has
    // completed). Mounting the editor's QuillEditor while the dialog route was
    // still tearing down corrupted the element tree
    // ("_dependents.isEmpty is not true") and crashed.
    if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
      ref.read(selectedSermonIdProvider.notifier).set(sermon.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              SermonEditorScreen(sermonId: sermon.id, isFullScreen: true),
        ),
      );
    }
  }
}

/// A compact, tappable coloured tag chip shown beside a sermon's series.
/// Tapping pins the tag as the list's active filter.
class _TagChip extends StatelessWidget {
  final TagData tag;
  final VoidCallback onTap;

  const _TagChip({required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = tagChipStyle(context, tag.colorHex);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: style.border),
        ),
        child: Text(
          '#${tag.name}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: style.foreground),
        ),
      ),
    );
  }
}

/// New-sermon dialog. A [StatefulWidget] so its controllers are disposed in
/// [State.dispose] — i.e. after the route is fully removed — rather than the
/// instant `showDialog` returns, which raced the dismiss animation and threw
/// "TextEditingController used after disposed". Returns the entered
/// (title, series) via [Navigator.pop], or null on cancel.
class _NewSermonDialog extends StatefulWidget {
  const _NewSermonDialog();

  @override
  State<_NewSermonDialog> createState() => _NewSermonDialogState();
}

class _NewSermonDialogState extends State<_NewSermonDialog> {
  final _titleController = TextEditingController();
  final _seriesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _seriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Sermon'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _seriesController,
            decoration: const InputDecoration(labelText: 'Series (Optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, (
            title: _titleController.text,
            series: _seriesController.text.isNotEmpty
                ? _seriesController.text
                : null,
          )),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
