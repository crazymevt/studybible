import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/action_providers.dart';
import '../../data/user_store.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

class HideCompletedActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setHide(bool val) => state = val;
}

final hideCompletedActionsProvider =
    NotifierProvider<HideCompletedActionsNotifier, bool>(
  () => HideCompletedActionsNotifier(),
);

class ActionItemsPanel extends ConsumerWidget {
  const ActionItemsPanel({super.key});

  static final _dueFormat = DateFormat('MMM d, y · h:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(actionItemsProvider);
    final hideCompleted = ref.watch(hideCompletedActionsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actions', style: Theme.of(context).textTheme.titleMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Hide Completed'),
                  Switch(
                    value: hideCompleted,
                    onChanged: (val) => ref
                        .read(hideCompletedActionsProvider.notifier)
                        .setHide(val),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Action',
                    onPressed: () => _showActionDialog(context, ref),
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
            child: actionsAsync.when(
            data: (actions) {
              final visible = hideCompleted
                  ? actions.where((a) => a.completedAt == null).toList()
                  : actions;
              if (visible.isEmpty) {
                return EmptyState(
                  icon: hideCompleted
                      ? Icons.task_alt
                      : Icons.checklist_outlined,
                  title: hideCompleted ? 'Nothing outstanding' : 'No actions yet',
                  message: hideCompleted
                      ? 'All caught up — no open actions.'
                      : 'Tap + to add a follow-up action.',
                );
              }
              return ListView.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _ActionTile(action: visible[index]),
              );
            },
            loading: () => const SkeletonList(),
            error: (err, stack) => const EmptyState(
              icon: Icons.error_outline,
              title: 'Couldn\'t load actions',
            ),
          ),
          ),
        ),
      ],
    );
  }

  static String formatDue(int dueAt) =>
      _dueFormat.format(DateTime.fromMillisecondsSinceEpoch(dueAt).toLocal());
}

class _ActionTile extends ConsumerWidget {
  final ActionItem action;
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = action.completedAt != null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isOverdue =
        !isCompleted && action.dueAt != null && now >= action.dueAt!;
    final theme = Theme.of(context);

    final subtitleParts = <String>[
      'Created: ${DateTime.fromMillisecondsSinceEpoch(action.createdAt).toLocal().toString().split(' ')[0]}',
    ];
    if (action.dueAt != null) {
      subtitleParts.add('Due: ${ActionItemsPanel.formatDue(action.dueAt!)}');
    }

    return ExpansionTile(
      leading: Checkbox(
        value: isCompleted,
        onChanged: (val) {
          if (val != null) {
            ref.read(actionItemActionProvider).toggleCompleted(action.id, val);
          }
        },
      ),
      title: Text(
        action.title,
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        subtitleParts.join('   '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: isOverdue ? theme.colorScheme.error : null,
          fontWeight: isOverdue ? FontWeight.bold : null,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              action.description.isEmpty ? 'No description' : action.description,
            ),
          ),
        ),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
              onPressed: () => _showActionDialog(context, ref, action: action),
            ),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete Action'),
                    content: const Text(
                      'Are you sure you want to delete this action?',
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
                      .read(actionItemActionProvider)
                      .deleteActionItem(action.id);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

void _showActionDialog(BuildContext context, WidgetRef ref,
    {ActionItem? action}) {
  showDialog(
    context: context,
    builder: (_) => _ActionDialog(action: action),
  );
}

/// Add/edit dialog. A [ConsumerStatefulWidget] so its controllers are disposed
/// in [State.dispose] (after the route is fully removed) rather than the instant
/// `showDialog` returns, which races the dismiss animation.
class _ActionDialog extends ConsumerStatefulWidget {
  final ActionItem? action;
  const _ActionDialog({this.action});

  @override
  ConsumerState<_ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends ConsumerState<_ActionDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.action?.title ?? '');
    _descCtrl = TextEditingController(text: widget.action?.description ?? '');
    final dueAt = widget.action?.dueAt;
    _due = dueAt != null
        ? DateTime.fromMillisecondsSinceEpoch(dueAt).toLocal()
        : null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _due != null
          ? TimeOfDay.fromDateTime(_due!)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (!mounted) return;
    final t = time ?? const TimeOfDay(hour: 9, minute: 0);
    setState(() {
      _due = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    await ref.read(actionItemActionProvider).saveActionItem(
          id: widget.action?.id,
          title: title,
          description: _descCtrl.text.trim(),
          dueAt: _due?.millisecondsSinceEpoch,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.action == null ? 'Add Action' : 'Edit Action'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Action'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Due date & time'),
              subtitle: Text(
                _due == null
                    ? 'Not set — tap to add'
                    : ActionItemsPanel.formatDue(_due!.millisecondsSinceEpoch),
              ),
              trailing: _due != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear due date',
                      onPressed: () => setState(() => _due = null),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _pickDue,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
