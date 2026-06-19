import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/user_store.dart';
import '../../app/reading_plan_providers.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';

class ReadingPlanDetailScreen extends ConsumerWidget {
  final ReadingPlan plan;

  const ReadingPlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(readingPlanDaysProvider(plan.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
      ),
      body: daysAsync.when(
        data: (days) {
          if (days.isEmpty) {
            return const Center(child: Text('No days found in this plan.'));
          }

          return ListView.builder(
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return _DayCard(day: day);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DayCard extends ConsumerStatefulWidget {
  final ReadingPlanDay day;

  const _DayCard({required this.day});

  @override
  ConsumerState<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<_DayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(readingPlanItemsProvider(widget.day.id));

    String dateStr = '';
    if (widget.day.date != null) {
      dateStr = DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(widget.day.date!));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Checkbox(
              value: widget.day.completed,
              onChanged: (val) {
                if (val != null) {
                  ref.read(readingPlanControllerProvider).toggleDayComplete(widget.day, val);
                }
              },
            ),
            title: Text(
              'Day ${widget.day.dayNumber}',
              style: theme.textTheme.titleMedium?.copyWith(
                decoration: widget.day.completed ? TextDecoration.lineThrough : null,
                color: widget.day.completed ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
            subtitle: dateStr.isNotEmpty ? Text(dateStr) : null,
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ),
          if (_expanded)
            itemsAsync.when(
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    children: items.map((item) {
                      String refStr = '${item.bookName} ${item.startChapter}';
                      if (item.startVerse != null) {
                        refStr += ':${item.startVerse}';
                      }
                      if (item.endChapter != item.startChapter) {
                        refStr += '-${item.endChapter}';
                        if (item.endVerse != null) {
                          refStr += ':${item.endVerse}';
                        }
                      } else if (item.endVerse != null && item.endVerse != item.startVerse) {
                        refStr += '-${item.endVerse}';
                      }

                      return ListTile(
                        dense: true,
                        leading: Checkbox(
                          value: item.completed,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(readingPlanControllerProvider).toggleItemComplete(item, val);
                            }
                          },
                        ),
                        title: Text(
                          refStr,
                          style: TextStyle(
                            decoration: item.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: () {
                            // Navigate to reader
                            ref.read(navigationControllerProvider).navigateTo(
                                  bookName: item.bookName,
                                  chapter: item.startChapter,
                                );
                            ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: $e'),
              ),
            ),
        ],
      ),
    );
  }
}
