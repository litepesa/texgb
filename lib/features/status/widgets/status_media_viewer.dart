import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
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
  String _errorMessage = 'Failed to load media';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.statusItem.type == StatusType.video) {
      _initializeVideo();
    } else {
      // For images and text, set loading to false after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
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
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      if (widget.statusItem.type == StatusType.video) {
        _initializeVideo();
      } else {
        // For images and text, set loading to false after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      _videoController = VideoPlayerController.network(widget.statusItem.mediaUrl);
      
      // Add listener before initialization to catch early errors
      _videoController!.addListener(_videoListener);
      
      // Initialize video
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasError = false;
          _isLoading = false;
        });
        
        // Report video duration
        if (widget.onDurationChanged != null) {
          widget.onDurationChanged!(_videoController!.value.duration);
        }
        
        // Start playing if not paused
        if (!widget.isPaused) {
          _videoController!.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString().split(':').first}';
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
    
    // Check for errors
    if (_videoController != null && 
        _videoController!.value.hasError && !_hasError) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video playback error';
          _isLoading = false;
        });
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
    // If loading, show a centered loading indicator
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    // If there was an error, show error state
    if (_hasError) {
      return _buildErrorState();
    }
    
    switch (widget.statusItem.type) {
      case StatusType.image:
        return _buildImageViewer();
      case StatusType.video:
        return _buildVideoViewer();
      case StatusType.text:
        return _buildTextViewer();
      default:
        return const Center(
          child: Text(
            'Unsupported media type',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (widget.statusItem.type == StatusType.video)
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
  
  Widget _buildImageViewer() {
    final modernTheme = context.modernTheme;
    
    return CachedNetworkImage(
      imageUrl: widget.statusItem.mediaUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(
          color: modernTheme.primaryColor ?? Colors.white,
        ),
      ),
      errorWidget: (context, url, error) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, color: Colors.white, size: 48),
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
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      imageBuilder: (context, imageProvider) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildVideoViewer() {
    if (!_isVideoInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            VideoPlayer(_videoController!),
            
            // Show play icon when paused
            if (widget.isPaused)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextViewer() {
    final modernTheme = context.modernTheme;
    
    // Create a more attractive text status display
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade800,
            Colors.purple.shade500,
            Colors.indigo.shade500,
          ],
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          widget.statusItem.mediaUrl,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}