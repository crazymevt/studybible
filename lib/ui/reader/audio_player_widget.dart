import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../app/app_state.dart';
import '../../app/audio_providers.dart';
import '../../app/content_providers.dart';
import '../../app/dashboard_providers.dart';
import '../../app/reader_state.dart';
import '../../data/logging.dart';

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
  double _playbackSpeed = 1.0;
  double? _dragValue; // non-null while the user is scrubbing the slider
  Timer? _sleepTimer;
  int? _sleepMinutes; // active sleep-timer duration, null when off
  StreamSubscription? _playerStateSubscription;

  static const List<double> _speedOptions = [0.75, 1.0, 1.25, 1.5, 2.0];
  static const List<int> _sleepOptions = [15, 30, 45, 60];

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
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  /// Move to an adjacent chapter from the player, preserving playback: if audio
  /// is currently playing, the next chapter auto-plays once loaded.
  void _skipChapter({required bool forward}) {
    _shouldAutoPlay = _player.playing;
    final nav = ref.read(navigationControllerProvider);
    if (forward) {
      nav.nextChapter();
    } else {
      nav.previousChapter();
    }
  }

  void _cycleSpeed() {
    final i = _speedOptions.indexOf(_playbackSpeed);
    final next = _speedOptions[(i + 1) % _speedOptions.length];
    setState(() => _playbackSpeed = next);
    _player.setSpeed(next);
  }

  void _setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    setState(() => _sleepMinutes = minutes);
    if (minutes == null) return;
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      _player.pause();
      if (mounted) setState(() => _sleepMinutes = null);
    });
  }

  // Shared pill container for the secondary controls.
  Widget _chip(BuildContext context, {required Widget child, bool active = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildSpeedChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = _playbackSpeed == _playbackSpeed.roundToDouble()
        ? '${_playbackSpeed.toStringAsFixed(0)}×'
        : '$_playbackSpeed×';
    final active = _playbackSpeed != 1.0;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _cycleSpeed,
      child: _chip(
        context,
        active: active,
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

  Widget _buildVoiceChip(BuildContext context, ChapterAudioData audioData) {
    final scheme = Theme.of(context).colorScheme;
    return _chip(
      context,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.record_voice_over, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: audioData.activeVoice,
              icon: Icon(Icons.arrow_drop_down, size: 20, color: scheme.onSurfaceVariant),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
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
        ],
      ),
    );
  }

  Widget _buildSleepChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _sleepMinutes != null;
    return PopupMenuButton<int?>(
      tooltip: 'Sleep timer',
      onSelected: _setSleepTimer,
      itemBuilder: (context) => [
        const PopupMenuItem<int?>(value: null, child: Text('Off')),
        ..._sleepOptions.map(
          (m) => PopupMenuItem<int?>(value: m, child: Text('$m minutes')),
        ),
      ],
      child: _chip(
        context,
        active: active,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bedtime, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              active ? '$_sleepMinutes min' : 'Sleep',
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

  Future<void> _loadAudio(String url) async {
    if (_currentUrl == url) return;
    _currentUrl = url;
    // Note: this method is invoked from build(); all setState() calls below
    // run only after the first await, never synchronously during build.
    try {
      await _player.setUrl(url);
      await _player.setSpeed(_playbackSpeed);
      if (_shouldAutoPlay) {
        _shouldAutoPlay = false;
        _player.play();
      }
      if (_loadFailed && mounted) setState(() => _loadFailed = false);
    } catch (e, stack) {
      logError(e, stack, context: 'AudioPlayerWidget._loadAudio');
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
      // Plain assignment (not setState): we're in build and returning an empty
      // widget anyway; this just avoids a stale error flashing when audio
      // becomes available again.
      _loadFailed = false;
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(80),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                final maxMs = duration.inMilliseconds.toDouble() > 0
                    ? duration.inMilliseconds.toDouble()
                    : 1.0;
                // While scrubbing, show the dragged position, not the stream's.
                final sliderValue = (_dragValue ?? position.inMilliseconds.toDouble())
                    .clamp(0.0, maxMs);
                final labelMs = (_dragValue ?? position.inMilliseconds.toDouble()).round();

                String formatDuration(Duration d) {
                  String twoDigits(int n) => n.toString().padLeft(2, "0");
                  String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
                  String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
                  if (d.inHours > 0) return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
                  return "$twoDigitMinutes:$twoDigitSeconds";
                }

                final timeStyle = Theme.of(context).textTheme.labelSmall;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                      ),
                      child: Slider(
                        value: sliderValue,
                        max: maxMs,
                        // Update only local state while dragging; seek on release
                        // so we don't spam the player on every pixel of movement.
                        onChanged: (value) {
                          setState(() => _dragValue = value);
                        },
                        onChangeEnd: (value) {
                          _player.seek(Duration(milliseconds: value.round()));
                          setState(() => _dragValue = null);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatDuration(Duration(milliseconds: labelMs)), style: timeStyle),
                          Text(formatDuration(duration), style: timeStyle),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Controls — FittedBox keeps the 5-button row from overflowing on
            // very narrow screens by scaling it down.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 32.0,
                  tooltip: 'Previous chapter',
                  onPressed: () => _skipChapter(forward: false),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  iconSize: 28.0,
                  tooltip: 'Back 10 seconds',
                  onPressed: () {
                    final newPos = _player.position - const Duration(seconds: 10);
                    _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                  },
                ),
                const SizedBox(width: 12),
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
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  iconSize: 28.0,
                  tooltip: 'Forward 10 seconds',
                  onPressed: () {
                    final newPos = _player.position + const Duration(seconds: 10);
                    final dur = _player.duration ?? Duration.zero;
                    _player.seek(newPos > dur ? dur : newPos);
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 32.0,
                  tooltip: 'Next chapter',
                  onPressed: () => _skipChapter(forward: true),
                ),
              ],
              ),
            ),

            const SizedBox(height: 32),
            
            // Secondary controls: speed, voice actor, sleep timer
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildSpeedChip(context),
                _buildVoiceChip(context, audioData),
                _buildSleepChip(context),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
