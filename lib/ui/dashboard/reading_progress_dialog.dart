import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';
import '../../app/app_state.dart';
import '../../app/achievement_service.dart';

class ReadingProgressDialog extends ConsumerWidget {
  final Map<String, List<int>> coverage;

  const ReadingProgressDialog({super.key, required this.coverage});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Books Read',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: bibleChapters.length,
                itemBuilder: (context, index) {
                  final book = bibleChapters.keys.elementAt(index);
                  final readChapters = coverage[book] ?? [];

                  final totalChapters = bibleChapters[book]!;

                  return ExpansionTile(
                    title: Text(book),
                    subtitle: Text(
                      '${readChapters.length} / $totalChapters chapters read',
                    ),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(totalChapters, (idx) {
                          final chapter = idx + 1;
                          final isRead = readChapters.contains(chapter);
                          return InkWell(
                            onTap: () {
                              ref
                                  .read(selectedBookNameProvider.notifier)
                                  .set(book);
                              ref
                                  .read(selectedChapterProvider.notifier)
                                  .set(chapter);
                              ref
                                  .read(appModuleProvider.notifier)
                                  .setModule(AppModule.reader);
                              Navigator.pop(context);
                            },
                            child: Chip(
                              label: Text('$chapter'),
                              backgroundColor: isRead
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.1),
                              avatar: isRead
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.green,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
