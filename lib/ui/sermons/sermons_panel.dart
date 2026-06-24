import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/sermon_providers.dart';
import 'export_dialog.dart';
import 'sermon_editor_screen.dart';
import '../common/breakpoints.dart';

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
            child: sermonsAsync.when(
              data: (sermons) {
                if (sermons.isEmpty) {
                  return const Center(child: Text('No sermons yet. Tap + to create one.'));
                }
                return ListView.builder(
                  itemCount: sermons.length,
                  itemBuilder: (context, index) {
                    final sermon = sermons[index];
                    return ListTile(
                      title: Text(sermon.title.isEmpty ? 'Untitled Sermon' : sermon.title),
                      subtitle: Text(sermon.series ?? 'No Series'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => ref.read(sermonActionProvider).deleteSermon(sermon.id),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewSermonDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final seriesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Sermon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: seriesController,
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
            onPressed: () async {
              final sermon = await ref.read(sermonActionProvider).createSermon(
                titleController.text,
                series: seriesController.text.isNotEmpty ? seriesController.text : null,
              );
              if (context.mounted) {
                Navigator.pop(context);
                if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
                  ref.read(selectedSermonIdProvider.notifier).set(sermon.id);
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SermonEditorScreen(sermonId: sermon.id, isFullScreen: true),
                  ));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    titleController.dispose();
    seriesController.dispose();
  }
}
