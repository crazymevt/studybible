import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/journal_providers.dart';
import '../tags/tag_editor_dialog.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

class HideAnsweredPrayersNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setHide(bool val) => state = val;
}

final hideAnsweredPrayersProvider =
    NotifierProvider<HideAnsweredPrayersNotifier, bool>(
      () => HideAnsweredPrayersNotifier(),
    );

class PrayerTrackerPanel extends ConsumerWidget {
  const PrayerTrackerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayersAsync = ref.watch(prayersProvider);
    final hideAnswered = ref.watch(hideAnsweredPrayersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prayer Tracker',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Hide Answered'),
                  Switch(
                    value: hideAnswered,
                    onChanged: (val) => ref
                        .read(hideAnsweredPrayersProvider.notifier)
                        .setHide(val),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Prayer',
                    onPressed: () => _showAddPrayerDialog(context, ref),
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
            child: prayersAsync.when(
            data: (prayers) {
              final visiblePrayers = hideAnswered
                  ? prayers.where((p) => p.answeredAt == null).toList()
                  : prayers;

              if (visiblePrayers.isEmpty) {
                return EmptyState(
                  icon: hideAnswered
                      ? Icons.volunteer_activism
                      : Icons.favorite_outline,
                  title: hideAnswered ? 'No open prayers' : 'No prayers yet',
                  message: hideAnswered
                      ? 'Every prayer here has been answered.'
                      : 'Tap + to add someone or something to pray for.',
                );
              }

              return ListView.separated(
                itemCount: visiblePrayers.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final prayer = visiblePrayers[index];
                  final isAnswered = prayer.answeredAt != null;

                  return ExpansionTile(
                    leading: Checkbox(
                      value: isAnswered,
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(prayerActionProvider)
                              .toggleAnswered(prayer.id, val);
                        }
                      },
                    ),
                    title: Text(
                      prayer.name,
                      style: TextStyle(
                        decoration: isAnswered
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      'Created: ${DateTime.fromMillisecondsSinceEpoch(prayer.createdAt).toLocal().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            prayer.description.isEmpty
                                ? 'No description'
                                : prayer.description,
                          ),
                        ),
                      ),
                      if (isAnswered)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Answered on: ${DateTime.fromMillisecondsSinceEpoch(prayer.answeredAt!).toLocal().toString().split(' ')[0]}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            onPressed: () => _showAddPrayerDialog(
                              context,
                              ref,
                              prayerId: prayer.id,
                              initialName: prayer.name,
                              initialDesc: prayer.description,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.label, size: 18),
                            label: const Text('Tags'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => TagEditorDialog(
                                  entityId: prayer.id,
                                  entityType: 'prayer',
                                ),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete Prayer'),
                                  content: const Text(
                                    'Are you sure you want to delete this prayer?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref
                                    .read(prayerActionProvider)
                                    .deletePrayer(prayer.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const SkeletonList(),
            error: (err, stack) => const EmptyState(
              icon: Icons.error_outline,
              title: 'Couldn\'t load prayers',
            ),
          ),
          ),
        ),
      ],
    );
  }

  void _showAddPrayerDialog(
    BuildContext context,
    WidgetRef ref, {
    String? prayerId,
    String? initialName,
    String? initialDesc,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final descCtrl = TextEditingController(text: initialDesc);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(prayerId == null ? 'Add Prayer' : 'Edit Prayer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
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
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                if (name.isNotEmpty) {
                  await ref
                      .read(prayerActionProvider)
                      .savePrayer(prayerId, name, desc);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      descCtrl.dispose();
    });
  }
}
