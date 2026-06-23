import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../app/app_state.dart';
import '../../app/audio_providers.dart';
import '../../app/content_providers.dart';
import '../../app/dashboard_providers.dart';
import '../../app/reader_state.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;
  bool _shouldAutoPlay = false;
  bool _loadFailed = false;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onChapterComplete();
      }
    });
  }

  Future<void> _onChapterComplete() async {
    _shouldAutoPlay = true;

    final book = ref.read(selectedBookNameProvider);
    final chapter = ref.read(selectedChapterProvider);

    // Mark the just-finished chapter read on completion, if enabled. This
    // runs before nextChapter() and independently of whether navigation
    // actually advances, so the final chapter of the Bible (which has no
    // next chapter to move to) is still credited.
    // Fire-and-forget, but guard the unawaited future so a DB/device-id
    // failure doesn't surface as an unhandled async error.
    if (ref.read(audioAdvanceMarksReadProvider)) {
      ref
          .read(dashboardActionProvider)
          .markChapterRead(book, chapter)
          .catchError((Object e) => debugPrint('Failed to mark read: $e'));
    }

    await ref.read(navigationControllerProvider).nextChapter();

    // If nothing advanced (e.g. the final chapter of the Bible), clear the
    // pending auto-play so it doesn't linger and surprise the next load.
    if (!mounted) return;
    if (ref.read(selectedBookNameProvider) == book &&
        ref.read(selectedChapterProvider) == chapter) {
      _shouldAutoPlay = false;
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadAudio(String url) async {
    if (_currentUrl == url) return;
    _currentUrl = url;
    if (_loadFailed && mounted) setState(() => _loadFailed = false);
    try {
      await _player.setUrl(url);
      if (_shouldAutoPlay) {
        _shouldAutoPlay = false;
        _player.play();
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
      _shouldAutoPlay = false;
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _retryLoad() async {
    final url = _currentUrl;
    if (url == null) return;
    _currentUrl = null; // force _loadAudio to re-attempt the same url
    _shouldAutoPlay = true;
    await _loadAudio(url);
  }

  @override
  Widget build(BuildContext context) {
    final audioData = ref.watch(chapterAudioProvider);

    if (audioData == null) {
      _player.stop();
      _currentUrl = null;
      return const SizedBox.shrink();
    }

    _loadAudio(audioData.url);

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
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Now Playing',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ref.watch(selectedBookNameProvider)} ${ref.watch(selectedChapterProvider)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_loadFailed) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Could not load audio.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _retryLoad,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Slider
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _player.duration ?? Duration.zero;

                String formatDuration(Duration d) {
                  String twoDigits(int n) => n.toString().padLeft(2, "0");
                  String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
                  String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
                  if (d.inHours > 0) return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
                  return "$twoDigitMinutes:$twoDigitSeconds";
                }

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble(),
                        max: duration.inMilliseconds.toDouble() > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          _player.seek(Duration(milliseconds: value.round()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatDuration(position), style: const TextStyle(fontSize: 12)),
                          Text(formatDuration(duration), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  iconSize: 32.0,
                  onPressed: () {
                    final newPos = _player.position - const Duration(seconds: 10);
                    _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                  },
                ),
                const SizedBox(width: 24),
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;

                    Widget playPauseIcon;
                    if (processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      playPauseIcon = const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      );
                    } else if (playing != true) {
                      playPauseIcon = const Icon(Icons.play_circle_fill, size: 64);
                    } else if (processingState != ProcessingState.completed) {
                      playPauseIcon = const Icon(Icons.pause_circle_filled, size: 64);
                    } else {
                      playPauseIcon = const Icon(Icons.replay_circle_filled, size: 64);
                    }

                    return IconButton(
                      icon: playPauseIcon,
                      iconSize: 64.0,
                      padding: EdgeInsets.zero,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        if (playing != true) {
                          _player.play();
                        } else if (processingState != ProcessingState.completed) {
                          _player.pause();
                        } else {
                          _player.seek(Duration.zero);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  iconSize: 32.0,
                  onPressed: () {
                    final newPos = _player.position + const Duration(seconds: 10);
                    final dur = _player.duration ?? Duration.zero;
                    _player.seek(newPos > dur ? dur : newPos);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Voice Actor
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.record_voice_over, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: audioData.activeVoice,
                      icon: Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      isDense: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          ref.read(selectedVoiceProvider.notifier).setVoice(newValue);
                        }
                      },
                      items: audioData.availableVoices.map<DropdownMenuItem<String>>((String value) {
                        final formattedName = value[0].toUpperCase() + value.substring(1);
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(formattedName),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
