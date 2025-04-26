import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MediaViewerScreen extends StatefulWidget {
  final String mediaUrl;
  final bool isImage;
  final String? caption;
  final String? senderName;
  
  const MediaViewerScreen({
    Key? key,
    required this.mediaUrl,
    required this.isImage,
    this.caption,
    this.senderName,
  }) : super(key: key);

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  bool _hasError = false;
  bool _showControls = true;
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    
    // Enter fullscreen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    if (!widget.isImage) {
      _initializeVideoPlayer();
    } else {
      setState(() {
        _isInitializing = false;
      });
    }
    
    // Auto-hide controls after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }
  
  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.network(widget.mediaUrl);
      await _videoController!.initialize();
      
      // Create a custom controller with bare minimum controls
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showOptions: false,
        showControls: false, // Disable built-in controls
        allowMuting: false,
        allowPlaybackSpeedChanging: false,
        allowFullScreen: false,
        
        // We'll create our own minimal progress indicator
      );
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        
        // Start the video
        _videoController!.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      }
      debugPrint('Error initializing video: $e');
    }
  }
  
  @override
  void dispose() {
    // Restore normal UI mode when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _videoController?.dispose();
    _chewieController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }
  
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      // Auto-hide after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        // Enable swipe down to dismiss
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media content
            Center(
              child: _isInitializing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _hasError
                      ? _buildErrorWidget()
                      : widget.isImage
                          ? _buildImageViewer()
                          : _buildVideoPlayer(),
            ),
            
            // Minimal header - just a close button
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Visibility(
                visible: _showControls,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Caption display (only if available)
            if (widget.caption != null && widget.caption!.isNotEmpty)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Visibility(
                  visible: _showControls,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        widget.caption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 48,
        ),
        const SizedBox(height: 16),
        const Text(
          'Failed to load media',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (widget.isImage) {
              setState(() {
                _hasError = false;
              });
            } else {
              setState(() {
                _isInitializing = true;
                _hasError = false;
              });
              _initializeVideoPlayer();
            }
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
  
  Widget _buildImageViewer() {
    // Using InteractiveViewer for zoom and pan
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 3.0,
      child: CachedNetworkImage(
        imageUrl: widget.mediaUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasError) {
              setState(() {
                _hasError = true;
              });
            }
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
  
  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: Text(
          'Error loading video',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return Stack(
      children: [
        // Video player
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
        
        // Centered play/pause touch area
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
              _toggleControls();
            },
          ),
        ),
        
        // Custom minimal progress bar - only visible when controls are shown
        if (_showControls)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildMinimalProgressBar(),
          ),
      ],
    );
  }
  
  Widget _buildMinimalProgressBar() {
    final duration = _videoController!.value.duration;
    final position = _videoController!.value.position;
    
    // Format time display
    String formatDuration(Duration duration) {
      final minutes = duration.inMinutes.toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
    
    return SafeArea(
      child: Container(
        height: 30,
        padding: const EdgeInsets.only(bottom: 5),
        color: Colors.black38,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video progress with time display
            Expanded(
              child: Row(
                children: [
                  // Current time
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      formatDuration(position),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  
                  // Progress slider
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 1.5,
                        activeTrackColor: Theme.of(context).extension<ModernThemeExtension>()?.accentColor ?? Colors.green,
                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                        thumbColor: Theme.of(context).extension<ModernThemeExtension>()?.accentColor ?? Colors.green,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble(),
                        min: 0.0,
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _videoController!.seekTo(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                  ),
                  
                  // Total duration
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Text(
                      formatDuration(duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}