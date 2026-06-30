import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/sermon_providers.dart';
import 'export_dialog.dart';
import 'sermon_editor_screen.dart';
import '../common/breakpoints.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

class SermonsPanel extends ConsumerWidget {
  const SermonsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSermonId = ref.watch(selectedSermonIdProvider);
    if (activeSermonId != null) {
      return SermonEditorScreen(sermonId: activeSermonId, isFullScreen: false);
    }

    final sermonsAsync = ref.watch(allSermonsProvider);

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
                  'Sermons',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.file_upload),
                      tooltip: 'Export All',
                      onPressed: () {
                        sermonsAsync.whenData((sermons) {
                          if (sermons.isNotEmpty) {
                            ExportDialog.show(context, sermons);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No sermons to export.')),
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
                return ListView.builder(
                  itemCount: sermons.length,
                  itemBuilder: (context, index) {
                    final sermon = sermons[index];
                    return ListTile(
                      title: Text(sermon.title.isEmpty ? 'Untitled Sermon' : sermon.title),
                      subtitle: Text(sermon.series ?? 'No Series'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Delete Sermon',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Sermon'),
                              content: const Text('Are you sure you want to delete this sermon?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(sermonActionProvider).deleteSermon(sermon.id);
                          }
                        },
                      ),
                      onTap: () {
                        if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
                          ref.read(selectedSermonIdProvider.notifier).set(sermon.id);
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SermonEditorScreen(sermonId: sermon.id, isFullScreen: true),
                          ));
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
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            SermonEditorScreen(sermonId: sermon.id, isFullScreen: true),
      ));
    }
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
