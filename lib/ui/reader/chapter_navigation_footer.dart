import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/dashboard_providers.dart';
import '../../app/reader_state.dart';

class ChapterNavigationFooter extends ConsumerWidget {
  const ChapterNavigationFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manualMode = ref.watch(manualChapterReadProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                onPressed: () {
                  ref.read(navigationControllerProvider).previousChapter();
                },
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(navigationControllerProvider).nextChapter();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Next'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
          // In manual mode, the chapter is only marked read on demand here
          // (the auto timer is disabled in the reader).
          if (manualMode) ...[
            const SizedBox(height: 16),
            const _MarkChapterReadButton(),
          ],
        ],
      ),
    );
  }
}

class _MarkChapterReadButton extends ConsumerWidget {
  const _MarkChapterReadButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final progress = ref.watch(readingProgressProvider).value ?? const [];
    final isRead =
        progress.any((r) => r.bookName == book && r.chapter == chapter);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: Icon(isRead ? Icons.check_circle : Icons.check_circle_outline),
        label: Text(isRead ? 'Marked as Read' : 'Mark Chapter Read'),
        // Disabled once read; markChapterRead is idempotent regardless.
        onPressed: isRead
            ? null
            : () => ref
                .read(dashboardActionProvider)
                .markChapterRead(book, chapter),
      ),
    );
  }
}
