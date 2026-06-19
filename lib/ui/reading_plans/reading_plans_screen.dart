import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/reading_plan_providers.dart';
import '../app_drawer.dart';
import 'reading_plan_generator_screen.dart';
import 'reading_plan_detail_screen.dart';

class ReadingPlansScreen extends ConsumerWidget {
  const ReadingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(activeReadingPlansProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Plans'),
      ),
      drawer: const AppDrawer(),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No active reading plans',
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new plan to track your daily reading.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ReadingPlanGeneratorScreen(),
                      ));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Plan'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ReadingPlanDetailScreen(plan: plan),
                    ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                plan.title,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Plan?'),
                                    content: const Text('Are you sure you want to delete this reading plan?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () => Navigator.of(c).pop(true), 
                                        child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  ref.read(readingPlanControllerProvider).deletePlan(plan.id);
                                }
                              },
                            ),
                          ],
                        ),
                        if (plan.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            plan.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Started: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(plan.startDate))}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: plansAsync.asData?.value.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ReadingPlanGeneratorScreen(),
                ));
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
