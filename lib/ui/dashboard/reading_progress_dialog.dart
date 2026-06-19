import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';
import '../../app/app_state.dart';

class ReadingProgressDialog extends ConsumerWidget {
  final Map<String, List<int>> coverage;

  const ReadingProgressDialog({super.key, required this.coverage});

  // Example list of books for demonstration. In a full app, this comes from content_providers.
  static const _books = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth',
    'Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans'
  ];

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
                  Text('Books Read', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];
                  final readChapters = coverage[book] ?? [];
                  
                  return ExpansionTile(
                    title: Text(book),
                    subtitle: Text('${readChapters.length} chapters read'),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(10, (idx) {
                          // Mocking 10 chapters per book for now
                          final chapter = idx + 1;
                          final isRead = readChapters.contains(chapter);
                          return InkWell(
                            onTap: () {
                              ref.read(selectedBookNameProvider.notifier).set(book);
                              ref.read(selectedChapterProvider.notifier).set(chapter);
                              ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
                              Navigator.pop(context);
                            },
                            child: Chip(
                              label: Text('$chapter'),
                              backgroundColor: isRead ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                              avatar: isRead ? const Icon(Icons.check, size: 16, color: Colors.green) : null,
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
