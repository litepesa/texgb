import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:video_player/video_player.dart';

class StatusMediaViewer extends StatefulWidget {
  final StatusItemModel statusItem;
  final bool isPaused;
  final Function(Duration)? onDurationChanged;

  const StatusMediaViewer({
    Key? key,
    required this.statusItem,
    this.isPaused = false,
    this.onDurationChanged,
  }) : super(key: key);

  @override
  State<StatusMediaViewer> createState() => _StatusMediaViewerState();
}

class _StatusMediaViewerState extends State<StatusMediaViewer> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.statusItem.type == StatusType.video) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(StatusMediaViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle pause/resume for video
    if (widget.statusItem.type == StatusType.video && _isVideoInitialized) {
      if (widget.isPaused && _videoController!.value.isPlaying) {
        _videoController!.pause();
      } else if (!widget.isPaused && !_videoController!.value.isPlaying) {
        _videoController!.play();
      }
    }
    
    // Reinitialize video if status item changed
    if (widget.statusItem.itemId != oldWidget.statusItem.itemId) {
      _disposeVideo();
      if (widget.statusItem.type == StatusType.video) {
        _initializeVideo();
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.network(widget.statusItem.mediaUrl);
      
      // Initialize video
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasError = false;
        });
        
        // Report video duration
        if (widget.onDurationChanged != null) {
          widget.onDurationChanged!(_videoController!.value.duration);
        }
        
        // Start playing if not paused
        if (!widget.isPaused) {
          _videoController!.play();
        }
        
        // Listen for video completion
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
          _hasError = true;
        });
      }
      debugPrint('Error initializing video: $e');
    }
  }
  
  void _videoListener() {
    // Check if video reached the end
    if (_videoController != null && 
        _videoController!.value.position >= _videoController!.value.duration) {
      // Notify parent about completion
      if (widget.onDurationChanged != null) {
        widget.onDurationChanged!(Duration.zero);
      }
    }
  }
  
  void _disposeVideo() {
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    }
  }
  
  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.statusItem.type) {
      case StatusType.image:
        return _buildImageViewer();
      case StatusType.video:
        return _buildVideoViewer();
      case StatusType.text:
        return _buildTextViewer();
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildImageViewer() {
    return CachedNetworkImage(
      imageUrl: widget.statusItem.mediaUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildVideoViewer() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeVideo,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    if (!_isVideoInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }
  
  Widget _buildTextViewer() {
    // For text status (placeholder implementation - could be enhanced)
    return Container(
      color: Colors.purple,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          widget.statusItem.mediaUrl,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}