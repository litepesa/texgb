// lib/features/status/widgets/status_video_player.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;

  const StatusVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = true,
  }) : super(key: key);

  @override
  State<StatusVideoPlayer> createState() => _StatusVideoPlayerState();
}

class _StatusVideoPlayerState extends State<StatusVideoPlayer> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isError = false;
  String _errorMessage = '';
  bool _isLoading = true;
  bool _showControls = false;
  Timer? _hideControlsTimer;
  bool _isLikeAnimating = false;  // Track like animation state
  
  // Retry mechanism
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant StatusVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _retryCount = 0;
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      // Validate URL before attempting to initialize
      final Uri? videoUri = _validateUrl(widget.videoUrl);
      if (videoUri == null) {
        _handleError('Invalid video URL');
        return;
      }
      
      _videoPlayerController = VideoPlayerController.networkUrl(videoUri);
      
      // Add timeout for initialization
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Video initialization timed out');
        },
      );
      
      if (!mounted) return;
      
      // Check if video loaded successfully
      if (_videoPlayerController!.value.hasError) {
        throw Exception('Video player encountered an error: ${_videoPlayerController!.value.errorDescription}');
      }
      
      // Configure controller settings
      await _videoPlayerController!.setLooping(widget.looping);
      
      if (widget.autoPlay) {
        await _videoPlayerController!.play();
      }
      
      // Add listener for position updates and video completion
      _videoPlayerController!.addListener(_videoPlayerListener);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      _handleError(e.toString());
    }
  }
  
  void _videoPlayerListener() {
    // Rebuild when needed for progress indicator updates
    if (mounted && _showControls) {
      setState(() {});
    }
    
    // If video completed and we're not looping, show controls
    if (_videoPlayerController != null && 
        _videoPlayerController!.value.isInitialized &&
        _videoPlayerController!.value.position >= _videoPlayerController!.value.duration &&
        !widget.looping) {
      _showControlsOverlay();
    }
  }
  
  Uri? _validateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.isAbsolute || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        return null;
      }
      return uri;
    } catch (_) {
      return null;
    }
  }
  
  void _handleError(String message) {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      // Clean up before retry
      _cleanupController();
      
      // Exponential backoff for retries
      Future.delayed(Duration(milliseconds: 500 * _retryCount), () {
        if (mounted) {
          _initializePlayer();
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = message;
          _isLoading = false;
        });
      }
    }
  }
  
  Widget _buildErrorDisplay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Error loading video',
              style: TextStyle(color: Colors.white),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _retryCount = 0;
                _cleanupController();
                _initializePlayer();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingDisplay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(
          color: context.modernTheme.primaryColor,
        ),
      ),
    );
  }
  
  void _showControlsOverlay() {
    setState(() {
      _showControls = true;
    });
    
    _resetHideControlsTimer();
  }
  
  void _hideControlsOverlay() {
    if (mounted) {
      setState(() {
        _showControls = false;
      });
    }
    
    _cancelHideControlsTimer();
  }
  
  void _resetHideControlsTimer() {
    _cancelHideControlsTimer();
    _hideControlsTimer = Timer(const Duration(seconds: 3), _hideControlsOverlay);
  }
  
  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }
  
  Widget _buildVideoControls() {
    final Duration position = _videoPlayerController?.value.position ?? Duration.zero;
    final Duration duration = _videoPlayerController?.value.duration ?? Duration.zero;
    final bool isPlaying = _videoPlayerController?.value.isPlaying ?? false;
    
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: () {
            if (_showControls) {
              _hideControlsOverlay();
            } else {
              _showControlsOverlay();
            }
          },
          child: Container(
            color: Colors.black38,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top controls (if needed)
                const SizedBox(height: 8),
                
                // Center play/pause button
                Center(
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 64,
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        _videoPlayerController?.pause();
                      } else {
                        _videoPlayerController?.play();
                      }
                      _resetHideControlsTimer();
                    },
                  ),
                ),
                
                // Bottom progress bar and time indicators
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProgressBar(
                        position: position,
                        duration: duration,
                        onSeek: (value) {
                          _videoPlayerController?.seekTo(value);
                          _resetHideControlsTimer();
                        },
                        progressColor: context.modernTheme.primaryColor!,
                        thumbColor: context.modernTheme.primaryColor!,
                        baseBarColor: Colors.grey[700]!,
                        bufferedBarColor: Colors.grey[500]!,
                        bufferedPosition: _videoPlayerController?.value.buffered.isNotEmpty == true
                            ? _videoPlayerController!.value.buffered.last.end
                            : Duration.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Shows a heart animation when double-tapped
  void _showLikeAnimation() {
    setState(() {
      _isLikeAnimating = true;
    });
    
    // Automatically hide the animation after it completes
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLikeAnimating = false;
        });
      }
    });
    
    // Get current user ID and toggle like on the status post
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    
    if (currentUser != null) {
      // Find the status ID by getting the current status post from the provider
      final currentPosts = statusProvider.filteredStatusPosts;
      for (var post in currentPosts) {
        if (post.mediaUrls.contains(widget.videoUrl)) {
          statusProvider.toggleLikeStatusPost(
            statusId: post.statusId,
            userUid: currentUser.uid,
          );
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Check if the status tab is visible to control video play/pause
    final isStatusTabVisible = context.select<StatusProvider, bool>(
      (provider) => provider.isStatusTabVisible,
    );
    
    // Safe controller access with null checks
    if (_isInitialized && _videoPlayerController != null) {
      // Pause video when status tab is not visible
      if (!isStatusTabVisible && _videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
      }
      
      // Resume video when status tab becomes visible again
      if (isStatusTabVisible && 
          !_videoPlayerController!.value.isPlaying && 
          widget.autoPlay) {
        _videoPlayerController!.play();
      }
    }
    
    if (_isError) {
      return _buildErrorDisplay();
    }
    
    if (_isLoading || !_isInitialized) {
      return _buildLoadingDisplay();
    }
    
    return GestureDetector(
      onTap: _showControlsOverlay,
      onDoubleTap: _showLikeAnimation,
      child: Stack(
        children: [
          // Video player
          AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
          
          // Controls overlay
          if (_showControls)
            _buildVideoControls(),
            
          // Like animation overlay
          if (_isLikeAnimating)
            Positioned.fill(
              child: _LikeAnimation(),
            ),
        ],
      ),
    );
  }
  
  void _cleanupController() {
    if (_videoPlayerController != null) {
      if (_videoPlayerController!.value.isInitialized) {
        _videoPlayerController!.removeListener(_videoPlayerListener);
        _videoPlayerController!.pause();
      }
    }
  }

  void _disposeController() {
    _cleanupController();
    _cancelHideControlsTimer();
    
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }
}

// Separated Like Animation widget to avoid Overlay issues
class _LikeAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          return Opacity(
            opacity: value > 0.8 ? 2 - value * 2 : value,
            child: Transform.scale(
              scale: value * 1.5,
              child: const Icon(
                Icons.favorite,
                size: 100,
                color: Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom progress bar widget
class ProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final Function(Duration) onSeek;
  final Color progressColor;
  final Color bufferedBarColor;
  final Color baseBarColor;
  final Color thumbColor;

  const ProgressBar({
    Key? key,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.progressColor,
    required this.baseBarColor,
    required this.bufferedBarColor,
    required this.thumbColor,
    this.bufferedPosition = Duration.zero,
  }) : super(key: key);

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (DragStartDetails details) {
        _dragValue = details.localPosition.dx / context.size!.width;
        _dragValue = _dragValue!.clamp(0.0, 1.0);
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        setState(() {
          _dragValue = details.localPosition.dx / context.size!.width;
          _dragValue = _dragValue!.clamp(0.0, 1.0);
        });
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_dragValue != null) {
          final seekPosition = Duration(milliseconds: (_dragValue! * widget.duration.inMilliseconds).round());
          widget.onSeek(seekPosition);
          _dragValue = null;
        }
      },
      onTapDown: (TapDownDetails details) {
        final tapPosition = details.localPosition.dx / context.size!.width;
        final seekPosition = Duration(milliseconds: (tapPosition * widget.duration.inMilliseconds).round());
        widget.onSeek(seekPosition);
      },
      child: Container(
        height: 20,
        width: double.infinity,
        child: CustomPaint(
          painter: _ProgressBarPainter(
            position: _dragValue != null
                ? Duration(milliseconds: (_dragValue! * widget.duration.inMilliseconds).round())
                : widget.position,
            duration: widget.duration,
            bufferedPosition: widget.bufferedPosition,
            progressColor: widget.progressColor,
            bufferedBarColor: widget.bufferedBarColor,
            baseBarColor: widget.baseBarColor,
            thumbColor: widget.thumbColor,
          ),
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final Color progressColor;
  final Color bufferedBarColor;
  final Color baseBarColor;
  final Color thumbColor;

  _ProgressBarPainter({
    required this.position,
    required this.duration,
    required this.bufferedPosition,
    required this.progressColor,
    required this.bufferedBarColor,
    required this.baseBarColor,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barHeight = 4.0;
    final double handleRadius = 6.0;
    
    // Calculate positions
    final double playedWidth = position.inMilliseconds / 
        (duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds) * size.width;
    final double bufferedWidth = bufferedPosition.inMilliseconds / 
        (duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds) * size.width;
    
    // Base track
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromPoints(
        Offset(0, (size.height - barHeight) / 2),
        Offset(size.width, (size.height + barHeight) / 2),
      ),
      Radius.circular(barHeight / 2),
    );
    final basePaint = Paint()..color = baseBarColor;
    canvas.drawRRect(baseRect, basePaint);
    
    // Buffered track
    if (bufferedWidth > 0) {
      final bufferedRect = RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, (size.height - barHeight) / 2),
          Offset(bufferedWidth, (size.height + barHeight) / 2),
        ),
        Radius.circular(barHeight / 2),
      );
      final bufferedPaint = Paint()..color = bufferedBarColor;
      canvas.drawRRect(bufferedRect, bufferedPaint);
    }
    
    // Played track
    if (playedWidth > 0) {
      final playedRect = RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, (size.height - barHeight) / 2),
          Offset(playedWidth, (size.height + barHeight) / 2),
        ),
        Radius.circular(barHeight / 2),
      );
      final playedPaint = Paint()..color = progressColor;
      canvas.drawRRect(playedRect, playedPaint);
    }
    
    // Thumb
    final thumbPaint = Paint()..color = thumbColor;
    canvas.drawCircle(
      Offset(playedWidth, size.height / 2),
      handleRadius,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) {
    return position != oldDelegate.position ||
        duration != oldDelegate.duration ||
        bufferedPosition != oldDelegate.bufferedPosition;
  }
}