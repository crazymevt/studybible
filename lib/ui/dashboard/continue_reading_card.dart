import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/reading_position_providers.dart';
import '../../data/user_store.dart';

/// Dashboard handoff card: when another synced device has read past this one,
/// offers a one-tap jump to where that device left off. Renders nothing when
/// there is no newer cross-device position.
class ContinueReadingCard extends ConsumerWidget {
  const ContinueReadingCard({super.key});

  String _agoLabel(int epochMs) {
    final delta = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(epochMs));
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }

  void _resume(WidgetRef ref, ReadingPosition pos) {
    ref.read(selectedBookNameProvider.notifier).set(pos.bookName);
    ref.read(selectedChapterProvider.notifier).set(pos.chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(pos.verse ?? 1);
    ref.read(selectedVersesProvider.notifier).clear();
    ref.read(navigationControllerProvider).recordHistory(verse: pos.verse);
    ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(continueReadingProvider).value;
    if (position == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Card(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.auto_stories, color: scheme.onSecondaryContainer),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue reading',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${position.bookName} ${position.chapter} — '
                      '${readingPositionDeviceLabel(position.platform)}, '
                      '${_agoLabel(position.updatedAt)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _resume(ref, position),
                child: const Text('Resume'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
