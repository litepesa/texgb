import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StatusVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isPaused;
  
  const StatusVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.isPaused,
  }) : super(key: key);

  @override
  State<StatusVideoPlayer> createState() => _StatusVideoPlayerState();
}

class _StatusVideoPlayerState extends State<StatusVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }
  
  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.network(widget.videoUrl);
    
    try {
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Start playing automatically when initialized
        _controller.play();
        _controller.setLooping(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      debugPrint('Error initializing video player: $e');
    }
  }
  
  @override
  void didUpdateWidget(StatusVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle pause/resume when the isPaused prop changes
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.pause();
      } else {
        _controller.play();
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }
    
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}