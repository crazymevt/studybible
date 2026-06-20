import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../data/content_store.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

final currentDevotionalEntryProvider = FutureProvider<DevotionalEntry?>((ref) async {
  final id = ref.watch(selectedDevotionalIdProvider);
  final devotionals = ref.watch(devotionalsProvider).value ?? [];
  final effectiveId = id ?? (devotionals.isNotEmpty ? devotionals.first.id : null);
  final day = ref.watch(selectedDevotionalDayProvider);
  if (effectiveId == null) return null;
  
  final store = ref.watch(contentStoreProvider);
  final entries = await (store.select(store.devotionalEntries)..where((d) => d.devotionalId.equals(effectiveId) & d.day.equals(day))).get();
  if (entries.isNotEmpty) {
    return entries.first;
  }
  return null;
});

class DevotionalsPanel extends ConsumerWidget {
  const DevotionalsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devotionalsAsync = ref.watch(devotionalsProvider);
    final entryAsync = ref.watch(currentDevotionalEntryProvider);
    final selectedIdRaw = ref.watch(selectedDevotionalIdProvider);
    final selectedDay = ref.watch(selectedDevotionalDayProvider);

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
                  'Devotionals',
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
            child: devotionalsAsync.when(
        data: (devotionals) {
          if (devotionals.isEmpty) {
            return const Center(child: Text('No devotionals installed.'));
          }
          final selectedId = selectedIdRaw ?? devotionals.first.id;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedId,
                        items: devotionals.map((d) {
                          return DropdownMenuItem<int>(
                            value: d.id,
                            child: Text(d.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(selectedDevotionalIdProvider.notifier).set(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: selectedDay > 1
                          ? () => ref.read(selectedDevotionalDayProvider.notifier).decrement()
                          : null,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Day $selectedDay', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => ref.read(selectedDevotionalDayProvider.notifier).setToday(),
                          child: const Text('Today', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: selectedDay < 366
                          ? () => ref.read(selectedDevotionalDayProvider.notifier).increment()
                          : null,
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: entryAsync.when(
                  data: (entry) {
                    if (entry == null) {
                      return const Center(child: Text('No entry for this day.'));
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: HtmlWidget(
                        entry.textContent,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
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
