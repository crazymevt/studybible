import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/action_providers.dart';
import '../../app/app_state.dart';

class DashboardActionItemsWidget extends ConsumerWidget {
  const DashboardActionItemsWidget({super.key});

  static final _dueFormat = DateFormat('MMM d, y');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(actionItemsProvider);
    final theme = Theme.of(context);

    // We constrain the list to exactly 5 items' height.
    const double itemHeight = 60.0;
    const double listHeight = itemHeight * 5;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              ref
                  .read(journalsActiveTabProvider.notifier)
                  .setTab(JournalsActiveTab.actions);
              ref.read(appModuleProvider.notifier).setModule(AppModule.journalsPrayers);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.checklist, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Action Items',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: listHeight,
            child: actionsAsync.when(
              data: (allActions) {
                final actions = allActions.where((a) => a.completedAt == null).toList();
                if (actions.isEmpty) {
                  return const Center(child: Text('No action items.'));
                }
                return ListView.builder(
                  itemExtent: itemHeight,
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    // The list is pre-filtered to incomplete items, so every
                    // row here is uncompleted; we only flag overdue ones.
                    final action = actions[index];
                    final now = DateTime.now().millisecondsSinceEpoch;
                    final isOverdue = action.dueAt != null && now >= action.dueAt!;

                    String subtitle = 'Created: ${DateTime.fromMillisecondsSinceEpoch(action.createdAt).toLocal().toString().split(' ')[0]}';
                    if (action.dueAt != null) {
                      subtitle += '   Due: ${_dueFormat.format(DateTime.fromMillisecondsSinceEpoch(action.dueAt!).toLocal())}';
                    }

                    return InkWell(
                      onTap: () {
                        ref
                            .read(journalsActiveTabProvider.notifier)
                            .setTab(JournalsActiveTab.actions);
                        ref.read(appModuleProvider.notifier).setModule(AppModule.journalsPrayers);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: false,
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(actionItemActionProvider).toggleCompleted(action.id, val);
                                }
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    action.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isOverdue ? theme.colorScheme.error : null,
                                      fontWeight: isOverdue ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
