import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/reading_plan_providers.dart';
import '../../app/content_providers.dart';
import '../../app/app_state.dart';
import '../reading_plans/reading_plan_generator_screen.dart';

class SelectedPlanIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final _selectedPlanIdProvider =
    NotifierProvider<SelectedPlanIdNotifier, String?>(
      () => SelectedPlanIdNotifier(),
    );

class ReadingPlanPanel extends ConsumerWidget {
  const ReadingPlanPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlansAsync = ref.watch(activeReadingPlansProvider);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading Plans',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (MediaQuery.sizeOf(context).width > 900) {
                      ref.read(activeToolProvider.notifier).close();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
              child: activePlansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) {
                    return _EmptyState();
                  }

                  // Auto-select the first plan if none selected
                  var selectedId = ref.watch(_selectedPlanIdProvider);
                  if (selectedId == null ||
                      !plans.any((p) => p.id == selectedId)) {
                    selectedId = plans.first.id;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                          .read(_selectedPlanIdProvider.notifier)
                          .set(selectedId);
                    });
                  }

                  // Unused selectedPlan var removed

                  return _ActivePlanView(
                    plans: plans,
                    selectedPlanId: selectedId,
                    onPlanSelected: (id) =>
                        ref.read(_selectedPlanIdProvider.notifier).set(id),
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
}

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Plans',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a daily reading plan to read through the Bible at your own pace.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create New Plan'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReadingPlanGeneratorScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePlanView extends ConsumerWidget {
  final List<dynamic> plans; // Drift generated class ReadingPlan
  final String selectedPlanId;
  final ValueChanged<String?> onPlanSelected;

  const _ActivePlanView({
    required this.plans,
    required this.selectedPlanId,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(readingPlanDaysProvider(selectedPlanId));

    return Column(
      children: [
        if (plans.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPlanId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Active Plan',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: plans
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(
                              p.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onPlanSelected,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Plan',
                  onPressed: () => _confirmDelete(context, ref, selectedPlanId),
                ),
              ],
            ),
          ),

        if (plans.length == 1)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plans.first.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Plan',
                  onPressed: () => _confirmDelete(context, ref, selectedPlanId),
                ),
              ],
            ),
          ),

        const Divider(),

        Expanded(
          child: daysAsync.when(
            data: (days) {
              if (days.isEmpty)
                return const Center(child: Text('No days in this plan.'));

              // Find current day (first uncompleted day)
              final currentDayIndex = days.indexWhere((d) => !d.completed);

              if (currentDayIndex == -1) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                      SizedBox(height: 16),
                      Text('Plan Completed!'),
                    ],
                  ),
                );
              }

              final currentDay = days[currentDayIndex];
              return _DayView(
                day: currentDay,
                dayIndex: currentDayIndex,
                totalDays: days.length,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),

        // Add new plan button at the very bottom
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Another Plan'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReadingPlanGeneratorScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan?'),
        content: const Text(
          'Are you sure you want to permanently delete this reading plan and all its progress?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(readingPlanControllerProvider).deletePlan(planId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DayView extends ConsumerWidget {
  final dynamic day; // ReadingPlanDay
  final int dayIndex;
  final int totalDays;

  const _DayView({
    required this.day,
    required this.dayIndex,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(readingPlanItemsProvider(day.id));
    final nav = ref.read(navigationControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day ${day.dayNumber}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              if (day.date != null)
                Text(
                  DateFormat.yMMMd().format(
                    DateTime.fromMillisecondsSinceEpoch(day.date!),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: dayIndex / totalDays,
                backgroundColor: Colors.grey.withAlpha(50),
              ),
              const SizedBox(height: 4),
              Text(
                'Progress: $dayIndex / $totalDays days',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        Expanded(
          child: itemsAsync.when(
            data: (items) {
              if (items.isEmpty)
                return const Center(child: Text('No readings.'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final String refText = item.startChapter == item.endChapter
                      ? '${item.bookName} ${item.startChapter}'
                      : '${item.bookName} ${item.startChapter}-${item.endChapter}';

                  return ListTile(
                    leading: Checkbox(
                      value: item.completed,
                      onChanged: (val) {
                        ref
                            .read(readingPlanControllerProvider)
                            .toggleItemComplete(item, val ?? false);
                      },
                    ),
                    title: Text(
                      refText,
                      style: TextStyle(
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.completed ? Colors.grey : null,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      nav.navigateTo(
                        bookName: item.bookName,
                        chapter: item.startChapter,
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Complete Day', style: TextStyle(fontSize: 16)),
            onPressed: () {
              ref
                  .read(readingPlanControllerProvider)
                  .toggleDayComplete(day, true);
              // The UI will automatically rebuild and show the next uncompleted day
            },
          ),
        ),
      ],
    );
  }
}
