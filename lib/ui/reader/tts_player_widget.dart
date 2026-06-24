import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/tts_providers.dart';
import '../../data/content_store.dart';

/// Bottom-sheet "read aloud" control, styled to match [AudioPlayerWidget] but
/// driven by the device TTS engine instead of pre-recorded audio. Unlike the
/// recorded-audio player this works for any version.
class TtsPlayerWidget extends ConsumerWidget {
  const TtsPlayerWidget({super.key});

  static const List<double> _speedOptions = [0.75, 1.0, 1.25, 1.5, 2.0];

  List<Verse> _activeVerses(WidgetRef ref) {
    final map = ref.watch(parallelVersesProvider).value ?? {};
    if (map.isEmpty) return const [];
    final active = ref.watch(activeVersionsProvider);
    final primary = active.isNotEmpty ? active.first : map.keys.first;
    return map[primary] ?? map.values.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ttsState = ref.watch(ttsControllerProvider);
    final controller = ref.read(ttsControllerProvider.notifier);
    final book = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final verses = _activeVerses(ref);

    // When verses are selected, start read-aloud from the first of them rather
    // than the top of the chapter. 0 means "from the beginning".
    final selectedVerses = ref.watch(selectedVersesProvider);
    final startVerse = selectedVerses.isEmpty
        ? 0
        : selectedVerses.reduce((a, b) => a < b ? a : b);

    final isPlaying = ttsState.status == TtsStatus.playing;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Read Aloud',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '$book $chapter',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              ttsState.currentVerse != null
                  ? 'Verse ${ttsState.currentVerse}'
                  : startVerse > 0
                      ? 'Starts at verse $startVerse'
                      : 'Tap play to start',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined),
                  iconSize: 36.0,
                  tooltip: 'Stop',
                  onPressed:
                      ttsState.isActive ? () => controller.stop() : null,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                  ),
                  iconSize: 64.0,
                  padding: EdgeInsets.zero,
                  color: scheme.primary,
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: verses.isEmpty
                      ? null
                      : () => controller.toggle(verses, fromVerse: startVerse),
                ),
                const SizedBox(width: 24),
                // Spacer to visually balance the stop button.
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 32),

            // Speed control
            Center(child: _SpeedChip(rate: ttsState.rate)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SpeedChip extends ConsumerWidget {
  const _SpeedChip({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final options = TtsPlayerWidget._speedOptions;
    final label =
        rate == rate.roundToDouble() ? '${rate.toStringAsFixed(0)}×' : '$rate×';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        final i = options.indexOf(rate);
        final next = options[(i + 1) % options.length];
        ref.read(ttsControllerProvider.notifier).setRate(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: rate != 1.0
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
