import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StatusVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isPaused;
  final bool useTikTokStyle; // New property for TikTok-style display
  
  const StatusVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.isPaused,
    this.useTikTokStyle = true, // Default to TikTok style
  }) : super(key: key);

  @override
  State<StatusVideoPlayer> createState() => _StatusVideoPlayerState();
}

class _StatusVideoPlayerState extends State<StatusVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  double _aspectRatio = 9/16; // Default to portrait aspect ratio
  
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
        // Calculate aspect ratio while respecting TikTok style if enabled
        if (widget.useTikTokStyle) {
          // For TikTok style, we want to maintain a portrait orientation
          final videoAspectRatio = _controller.value.aspectRatio;
          
          // If the video is landscape, we'll force it into a portrait frame
          // by using the inverse of its aspect ratio but capped at 9:16
          if (videoAspectRatio > 1.0) {
            // Landscape video - constrain to portrait view
            _aspectRatio = 9/16;
          } else {
            // Already portrait - use actual ratio but cap at 9:16
            _aspectRatio = videoAspectRatio < (9/16) ? videoAspectRatio : (9/16);
          }
        } else {
          // Use the video's natural aspect ratio
          _aspectRatio = _controller.value.aspectRatio;
        }
        
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
    
    // Handle URL changes
    if (widget.videoUrl != oldWidget.videoUrl) {
      _controller.dispose();
      _isInitialized = false;
      _hasError = false;
      _initializeVideoPlayer();
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
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                });
                _initializeVideoPlayer();
              },
              child: const Text('Retry'),
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
    
    // Create a black container that maintains 9:16 aspect ratio for TikTok style
    return widget.useTikTokStyle
        ? Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: _aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        : Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          );
  }
}