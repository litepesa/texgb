// lib/features/chat/widgets/video_player_overlay.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

/// A full-screen video player overlay widget that can play videos from URLs.
/// 
/// Features:
/// - Full-screen video playback
/// - Play/pause controls
/// - Seek forward/backward (10 seconds)
/// - Progress bar with scrubbing
/// - Error handling with retry functionality
/// - Close button to exit player

class VideoPlayerOverlay extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onClose;
  final String? title;

  const VideoPlayerOverlay({
    super.key,
    required this.videoUrl,
    required this.onClose,
    this.title,
  });

  @override
  State<VideoPlayerOverlay> createState() => _VideoPlayerOverlayState();
}

class _VideoPlayerOverlayState extends State<VideoPlayerOverlay> {
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );

      await _videoPlayerController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _videoPlayerController!.play();
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        showSnackBar(context, 'Failed to load video');
      }
    }
  }

  void _togglePlayPause() {
    if (_videoPlayerController != null && _isInitialized) {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
      setState(() {});
    }
  }

  void _seekBackward() {
    if (_videoPlayerController != null && _isInitialized) {
      final position = _videoPlayerController!.value.position;
      final newPosition = position - const Duration(seconds: 10);
      _videoPlayerController!.seekTo(
        newPosition < Duration.zero ? Duration.zero : newPosition,
      );
    }
  }

  void _seekForward() {
    if (_videoPlayerController != null && _isInitialized) {
      final position = _videoPlayerController!.value.position;
      final duration = _videoPlayerController!.value.duration;
      final newPosition = position + const Duration(seconds: 10);
      _videoPlayerController!.seekTo(
        newPosition > duration ? duration : newPosition,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Header with close button
            _buildHeader(modernTheme),
            
            // Video player content
            Expanded(
              child: Center(
                child: _buildVideoContent(modernTheme),
              ),
            ),
            
            // Video controls
            if (_isInitialized && !_hasError)
              _buildVideoControls(modernTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
          ),
          Expanded(
            child: Text(
              widget.title ?? 'Shared Video',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildVideoContent(ModernThemeExtension modernTheme) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isInitialized) {
      return const CircularProgressIndicator(
        color: Colors.white,
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
          
          // Play/Pause overlay
          if (!_videoPlayerController!.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'Failed to load video',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please check your internet connection and try again',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _hasError = false;
              _isInitialized = false;
            });
            _initializeVideoPlayer();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildVideoControls(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            _videoPlayerController!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: modernTheme.primaryColor!,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white10,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _seekBackward,
                icon: const Icon(
                  Icons.replay_10,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _videoPlayerController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              
              IconButton(
                onPressed: _seekForward,
                icon: const Icon(
                  Icons.forward_10,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}