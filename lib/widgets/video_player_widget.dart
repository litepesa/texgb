import 'package:flutter/material.dart';
import 'package:textgb/common/videoviewerscreen.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:async';

// Import your VideoViewerScreen
// import 'video_viewer_screen.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.color,
    required this.viewOnly,
    this.aspectRatio,
    this.autoPlay = false,
    this.looping = false,
    this.allowFullScreen = true,
    this.errorBuilder,
    this.placeholder,
    this.controlsConfiguration,
    this.navigateToViewerOnTap = true, // New parameter to control navigation behavior
    this.customThumbnail, // Optional custom thumbnail
    this.videoTitle, // Optional video title for viewer screen
  });

  final String videoUrl;
  final Color color;
  final bool viewOnly;
  final double? aspectRatio;
  final bool autoPlay;
  final bool looping;
  final bool allowFullScreen;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget? placeholder;
  final ChewieProgressColors? controlsConfiguration;
  final bool navigateToViewerOnTap;
  final Widget? customThumbnail;
  final String? videoTitle;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _positionTimer;
  bool _isDisposed = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Only initialize the video player immediately if we're not using it as a thumbnail
    if (!widget.navigateToViewerOnTap || widget.customThumbnail == null) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      
      // Add listeners before initialization to catch early errors
      _videoPlayerController.addListener(_videoPlayerListener);
      
      await _videoPlayerController.initialize().catchError((error) {
        _handleVideoError('Failed to initialize video: $error');
        return;
      });
      
      if (_isDisposed) return;

      final effectiveAspectRatio = widget.aspectRatio ?? 
          (_videoPlayerController.value.aspectRatio != 0.0 
              ? _videoPlayerController.value.aspectRatio 
              : 16 / 9);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: effectiveAspectRatio,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: !widget.viewOnly,
        allowFullScreen: widget.allowFullScreen,
        errorBuilder: (context, errorMessage) {
          return widget.errorBuilder?.call(context, errorMessage) ??
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $errorMessage',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
        },
        materialProgressColors: widget.controlsConfiguration ??
            ChewieProgressColors(
              playedColor: widget.color,
              handleColor: widget.color,
              backgroundColor: widget.color.withOpacity(0.3),
              bufferedColor: widget.color.withOpacity(0.5),
            ),
      );
      
      // Only update state if the widget hasn't been disposed
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    } catch (error) {
      _handleVideoError('Error setting up video: $error');
    }
  }

  void _videoPlayerListener() {
    // Check for player errors
    if (_videoPlayerController.value.hasError && !_hasError) {
      _handleVideoError('Video playback error: ${_videoPlayerController.value.errorDescription}');
    }
  }

  void _handleVideoError(String message) {
    if (_isDisposed) return;
    
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = message;
    });
    
    debugPrint(_errorMessage);
  }

  void _navigateToViewer(BuildContext context) {
    // Pause video if playing
    if (_isInitialized && _videoPlayerController.value.isPlaying) {
      _videoPlayerController.pause();
    }
    
    // Navigate to the viewer screen
    Navigator.of(context).push(
      VideoViewerScreen.route(
        videoUrl: widget.videoUrl,
        videoTitle: widget.videoTitle,
        accentColor: widget.color,
      ),
    );
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only reinitialize if the URL changed to prevent unnecessary reloads
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _initializePlayer();
    } else if (oldWidget.color != widget.color || 
               oldWidget.viewOnly != widget.viewOnly ||
               oldWidget.autoPlay != widget.autoPlay ||
               oldWidget.looping != widget.looping) {
      // Update controller settings without full reinitialization
      _updateControllerSettings();
    }
  }

  void _updateControllerSettings() {
    if (_chewieController != null && !_isDisposed) {
      final oldController = _chewieController;
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: widget.aspectRatio ?? 
            (_videoPlayerController.value.aspectRatio != 0.0 
                ? _videoPlayerController.value.aspectRatio 
                : 16 / 9),
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: !widget.viewOnly,
        allowFullScreen: widget.allowFullScreen,
        materialProgressColors: widget.controlsConfiguration ??
            ChewieProgressColors(
              playedColor: widget.color,
              handleColor: widget.color,
              backgroundColor: widget.color.withOpacity(0.3),
              bufferedColor: widget.color.withOpacity(0.5),
            ),
      );
      
      // Dispose old controller after creating the new one
      oldController?.dispose();
      
      setState(() {});
    }
  }

  void _disposeControllers() {
    if (_isInitialized) {
      _videoPlayerController.removeListener(_videoPlayerListener);
      _videoPlayerController.dispose();
      _chewieController?.dispose();
      _positionTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we're in thumbnail mode with navigation
    if (widget.navigateToViewerOnTap && widget.customThumbnail != null) {
      return GestureDetector(
        onTap: () => _navigateToViewer(context),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio ?? 16 / 9,
          child: widget.customThumbnail!,
        ),
      );
    }

    // Regular video player with optional navigation
    return GestureDetector(
      onTap: widget.navigateToViewerOnTap 
          ? () => _navigateToViewer(context) 
          : null,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio ?? 16 / 9,
        child: _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return widget.placeholder ?? 
          Center(
            child: CircularProgressIndicator(
              color: widget.color,
            ),
          );
    }
    
    if (_hasError) {
      return widget.errorBuilder?.call(context, _errorMessage) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load video',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _initializePlayer,
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
    }
    
    if (widget.navigateToViewerOnTap) {
      // For clickable video, show a thumbnail with play button
      return Stack(
        alignment: Alignment.center,
        children: [
          // Video frame
          Chewie(controller: _chewieController!),
          
          // Play button overlay
          if (widget.navigateToViewerOnTap)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(16),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
        ],
      );
    }
    
    // Use a fadeIn animation for smoother transition
    return FadeTransition(
      opacity: AlwaysStoppedAnimation(1.0),
      child: Chewie(controller: _chewieController!),
    );
  }
}