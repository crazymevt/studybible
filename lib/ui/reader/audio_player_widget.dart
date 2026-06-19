import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../app/audio_providers.dart';
import '../../app/content_providers.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;
  bool _shouldAutoPlay = false;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _shouldAutoPlay = true;
        ref.read(navigationControllerProvider).nextChapter();
      }
    });
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
    try {
      await _player.setUrl(url);
      if (_shouldAutoPlay) {
        _shouldAutoPlay = false;
        _player.play();
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play / Pause Button
        StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                width: 16.0,
                height: 16.0,
                child: const CircularProgressIndicator(strokeWidth: 2),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 20.0,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 20.0,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 20.0,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _player.seek(Duration.zero),
              );
            }
          },
        ),

        // Seek Bar (Expanded)
        Expanded(
          child: StreamBuilder<Duration>(
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

              return Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                        trackHeight: 2.0,
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble(),
                        max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                        onChanged: (value) {
                          _player.seek(Duration(milliseconds: value.round()));
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${formatDuration(position)} / ${formatDuration(duration)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
        
        const SizedBox(width: 8),

        // Voice Actor Dropdown
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: audioData.activeVoice,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            style: Theme.of(context).textTheme.bodyMedium,
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
                child: Text(formattedName, style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
