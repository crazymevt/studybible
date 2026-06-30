import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

class MediaPlayerDialog extends StatefulWidget {
  final String videoId;

  const MediaPlayerDialog({super.key, required this.videoId});

  @override
  State<MediaPlayerDialog> createState() => _MediaPlayerDialogState();
}

class _MediaPlayerDialogState extends State<MediaPlayerDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false, // Use custom button
        mute: false,
      ),
    );
  }

  bool _isFullscreen = false;

  Future<void> _toggleFullscreen() async {
    final isWindowFullScreen = await windowManager.isFullScreen();
    if (!isWindowFullScreen) {
      await windowManager.setFullScreen(true);
      setState(() => _isFullscreen = true);
    } else {
      await windowManager.setFullScreen(false);
      setState(() => _isFullscreen = false);
    }
    // Resume video after macOS animation
    Future.delayed(const Duration(milliseconds: 800), () {
      _controller.playVideo();
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        backgroundColor: Colors.black,
        insetPadding: _isFullscreen ? EdgeInsets.zero : const EdgeInsets.all(24),
        shape: _isFullscreen
            ? const RoundedRectangleBorder()
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 12),
          child: SizedBox(
            width: _isFullscreen ? MediaQuery.of(context).size.width : null,
            height: _isFullscreen ? MediaQuery.of(context).size.height : null,
            child: _isFullscreen
                ? _buildContent()
                : AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildContent(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: YoutubePlayer(
            controller: _controller,
            backgroundColor: Colors.black,
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                IconButton(
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: _isFullscreen ? 'Exit full screen' : 'Full screen',
                  onPressed: _toggleFullscreen,
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
