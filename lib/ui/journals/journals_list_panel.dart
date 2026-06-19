import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/user_store.dart';
import '../../app/journal_providers.dart';
import 'journal_editor_panel.dart';

class SelectedJournalIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setId(String? id) => state = id;
}
final selectedJournalIdProvider = NotifierProvider<SelectedJournalIdNotifier, String?>(() => SelectedJournalIdNotifier());

class SelectedJournalDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}
final selectedJournalDateProvider = NotifierProvider<SelectedJournalDateNotifier, DateTime>(() => SelectedJournalDateNotifier());

class JournalsListPanel extends ConsumerWidget {
  const JournalsListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsProvider);
    final selectedId = ref.watch(selectedJournalIdProvider);

    final isDesktop = MediaQuery.sizeOf(context).width > 800;
    final selectedDate = ref.watch(selectedJournalDateProvider);

    ref.listen<AsyncValue<List<Journal>>>(journalsProvider, (previous, next) {
      if (previous?.value == null && next.value != null) {
        final journals = next.value!;
        final today = DateTime.now();
        final todayEntry = journals.where((j) {
          final d = DateTime.fromMillisecondsSinceEpoch(j.updatedAt).toLocal();
          return d.year == today.year && d.month == today.month && d.day == today.day;
        }).firstOrNull;
        if (todayEntry != null) {
          ref.read(selectedJournalIdProvider.notifier).setId(todayEntry.id);
        }
      }
    });

    void selectDate(DateTime date) {
      ref.read(selectedJournalDateProvider.notifier).setDate(date);
      final journals = ref.read(journalsProvider).value ?? [];
      final found = journals.where((j) {
        final d = DateTime.fromMillisecondsSinceEpoch(j.updatedAt).toLocal();
        return d.year == date.year && d.month == date.month && d.day == date.day;
      }).firstOrNull;
      
      if (found != null) {
        ref.read(selectedJournalIdProvider.notifier).setId(found.id);
      } else {
        ref.read(selectedJournalIdProvider.notifier).setId(null);
      }
    }

    return Column(
      children: [
        // Date Picker (visual only for now, or filters by date)
        if (isDesktop)
          CalendarDatePicker(
            key: ValueKey(selectedDate),
            initialDate: selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: selectDate,
          ),
        if (isDesktop)
          const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Entries', style: Theme.of(context).textTheme.titleMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDesktop)
                    IconButton(
                      icon: const Icon(Icons.today),
                      tooltip: 'Go to Today',
                      onPressed: () => selectDate(DateTime.now()),
                    ),
                  if (!isDesktop)
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      tooltip: 'Pick Date',
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null && context.mounted) {
                          selectDate(date);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('Journal Editor')),
                              body: const JournalEditorPanel(),
                            ),
                          ));
                        }
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      ref.read(selectedJournalIdProvider.notifier).setId(null);
                      if (!isDesktop) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('New Journal')),
                            body: const JournalEditorPanel(),
                          ),
                        ));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: journalsAsync.when(
            data: (journals) {
              if (journals.isEmpty) {
                return const Center(child: Text('No journal entries yet.'));
              }
              return ListView.builder(
                itemCount: journals.length,
                itemBuilder: (context, index) {
                  final journal = journals[index];
                  final isSelected = journal.id == selectedId;
                  
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    title: Text(
                      journal.title.isEmpty ? 'Untitled' : journal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      DateTime.fromMillisecondsSinceEpoch(journal.updatedAt).toLocal().toString().split(' ')[0],
                    ),
                    onTap: () {
                      ref.read(selectedJournalIdProvider.notifier).setId(journal.id);
                      final d = DateTime.fromMillisecondsSinceEpoch(journal.updatedAt).toLocal();
                      ref.read(selectedJournalDateProvider.notifier).setDate(d);
                      
                      if (!isDesktop) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('Edit Journal')),
                            body: const JournalEditorPanel(),
                          ),
                        ));
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}
