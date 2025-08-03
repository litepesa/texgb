// lib/features/status/widgets/video_status_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoStatusWidget extends StatefulWidget {
  final String? videoUrl;
  final File? videoFile;
  final String? caption;
  final bool autoPlay;
  final bool showControls;
  final VoidCallback? onTap;
  final Function(Duration)? onProgress;
  final Function()? onVideoEnd;

  const VideoStatusWidget({
    super.key,
    this.videoUrl,
    this.videoFile,
    this.caption,
    this.autoPlay = false,
    this.showControls = true,
    this.onTap,
    this.onProgress,
    this.onVideoEnd,
  });

  @override
  State<VideoStatusWidget> createState() => _VideoStatusWidgetState();
}

class _VideoStatusWidgetState extends State<VideoStatusWidget> {
  VideoPlayerController? _controller;
  String? _thumbnailPath;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showThumbnail = true;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _generateThumbnail();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoFile != null) {
        _controller = VideoPlayerController.file(widget.videoFile!);
      } else if (widget.videoUrl != null) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      } else {
        return;
      }

      await _controller!.initialize();
      
      _controller!.addListener(_videoListener);
      
      setState(() {
        _isInitialized = true;
      });

      if (widget.autoPlay) {
        _playVideo();
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _videoListener() {
    if (_controller == null) return;

    final isPlaying = _controller!.value.isPlaying;
    final isBuffering = _controller!.value.isBuffering;
    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (_isPlaying != isPlaying || _isBuffering != isBuffering) {
      setState(() {
        _isPlaying = isPlaying;
        _isBuffering = isBuffering;
      });
    }

    // Report progress
    if (widget.onProgress != null && duration != Duration.zero) {
      widget.onProgress!(position);
    }

    // Check if video ended
    if (position >= duration && duration != Duration.zero) {
      setState(() {
        _isPlaying = false;
        _showThumbnail = true;
      });
      widget.onVideoEnd?.call();
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      String? videoPath;
      
      if (widget.videoFile != null) {
        videoPath = widget.videoFile!.path;
      } else if (widget.videoUrl != null) {
        videoPath = widget.videoUrl!;
      }

      if (videoPath != null) {
        final thumbnail = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 400,
          quality: 75,
        );

        if (mounted) {
          setState(() {
            _thumbnailPath = thumbnail;
          });
        }
      }
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
    }
  }

  void _playVideo() {
    if (_controller != null && _isInitialized) {
      setState(() {
        _showThumbnail = false;
        _isPlaying = true;
      });
      _controller!.play();
    }
  }

  void _pauseVideo() {
    if (_controller != null && _isInitialized) {
      setState(() {
        _isPlaying = false;
      });
      _controller!.pause();
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _seekTo(Duration position) {
    if (_controller != null && _isInitialized) {
      _controller!.seekTo(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _togglePlayPause,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Video player or thumbnail
            if (_showThumbnail)
              _buildThumbnail()
            else if (_isInitialized)
              _buildVideoPlayer()
            else
              _buildLoadingState(),

            // Play/pause overlay
            if (_showThumbnail || !_isPlaying)
              _buildPlayButton(),

            // Buffering indicator
            if (_isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),

            // Caption overlay
            if (widget.caption != null && widget.caption!.isNotEmpty)
              _buildCaptionOverlay(),

            // Video controls (optional)
            if (widget.showControls && !_showThumbnail && _isInitialized)
              _buildVideoControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (_thumbnailPath != null) {
      return Image.file(
        File(_thumbnailPath!),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (widget.videoUrl != null) {
      // Fallback to network image if available
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.video_library,
            color: Colors.white54,
            size: 64,
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }
  }

  Widget _buildVideoPlayer() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildCaptionOverlay() {
    return Positioned(
      bottom: widget.showControls ? 80 : 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildVideoControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white38,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 8),
            
            // Time display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_controller!.value.position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDuration(_controller!.value.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Thumbnail generator utility
class VideoThumbnailGenerator {
  static Future<String?> generateThumbnail({
    required String videoPath,
    int maxHeight = 400,
    int quality = 75,
  }) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: maxHeight,
        quality: quality,
      );
      return thumbnail;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  static Future<String?> generateNetworkThumbnail({
    required String videoUrl,
    int maxHeight = 400,
    int quality = 75,
  }) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: maxHeight,
        quality: quality,
      );
      return thumbnail;
    } catch (e) {
      debugPrint('Error generating network video thumbnail: $e');
      return null;
    }
  }
}