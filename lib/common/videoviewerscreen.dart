import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:async';

class VideoViewerScreen extends StatefulWidget {
  final String videoUrl;
  final String? videoTitle;
  final Color accentColor;
  final bool allowOrientationChanges;

  const VideoViewerScreen({
    Key? key,
    required this.videoUrl,
    this.videoTitle,
    this.accentColor = const Color(0xFF2196F3),
    this.allowOrientationChanges = false, // Default to not changing orientation
  }) : super(key: key);

  static Route<void> route({
    required String videoUrl,
    String? videoTitle,
    Color accentColor = const Color(0xFF2196F3),
    bool allowOrientationChanges = false,
  }) {
    return MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => VideoViewerScreen(
        videoUrl: videoUrl,
        videoTitle: videoTitle,
        accentColor: accentColor,
        allowOrientationChanges: allowOrientationChanges,
      ),
    );
  }

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  bool _isInitialized = false;
  bool _isFullScreen = false;
  Timer? _hideControlsTimer;
  bool _showControls = true;
  final Duration _controlsTimeout = const Duration(seconds: 3);
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  double _bufferingProgress = 0.0;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // We're not automatically setting orientations when opening the screen
    // Only when the fullscreen button is explicitly pressed
    
    _initializePlayer();
    _startHideControlsTimer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      
      // Add listeners
      _videoPlayerController.addListener(_videoPlayerListener);
      
      await _videoPlayerController.initialize();
      
      setState(() {
        _isInitialized = true;
        _videoDuration = _videoPlayerController.value.duration;
      });
      
      // Start playing automatically
      _videoPlayerController.play();
      setState(() {
        _isPlaying = true;
      });
      
      // Set up position reporting timer
      _setupPositionReporting();
    } catch (error) {
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to initialize video: $error';
      });
      debugPrint(_errorMessage);
    }
  }

  void _videoPlayerListener() {
    // Check for player errors
    if (_videoPlayerController.value.hasError && !_isError) {
      setState(() {
        _isError = true;
        _errorMessage = 'Video playback error: ${_videoPlayerController.value.errorDescription}';
      });
      debugPrint(_errorMessage);
    }
    
    // Update playing state
    if (_isPlaying != _videoPlayerController.value.isPlaying) {
      setState(() {
        _isPlaying = _videoPlayerController.value.isPlaying;
      });
      
      if (_isPlaying) {
        _startHideControlsTimer();
      } else {
        _hideControlsTimer?.cancel();
        setState(() => _showControls = true);
      }
    }
  }

  void _setupPositionReporting() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_isInitialized) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _currentPosition = _videoPlayerController.value.position;
        
        // Calculate buffering progress
        if (_videoDuration.inMilliseconds > 0) {
          _bufferingProgress = _videoPlayerController.value.buffered.isEmpty
              ? 0.0
              : _videoPlayerController.value.buffered.last.end.inMilliseconds /
                _videoDuration.inMilliseconds;
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isFullScreen) {
      _setPreferredOrientations(true);
    }
  }
  
  void _setPreferredOrientations(bool fullscreen) {
    // Only change orientations if explicitly allowed by the widget parameter
    if (!widget.allowOrientationChanges) {
      setState(() => _isFullScreen = fullscreen);
      return;
    }
    
    if (fullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      setState(() => _isFullScreen = true);
    } else {
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        setState(() => _isFullScreen = false);
      }
    }
  }

  void _resetPreferredOrientations() {
    if (widget.allowOrientationChanges) {
      SystemChrome.setPreferredOrientations([]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleFullScreen() {
    _setPreferredOrientations(!_isFullScreen);
    _showControlsTemporarily();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(_controlsTimeout, () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _videoPlayerController.pause();
    } else {
      _videoPlayerController.play();
    }
    _showControlsTemporarily();
  }

  void _seekRelative(Duration offset) {
    final current = _videoPlayerController.value.position;
    final target = current + offset;
    final duration = _videoPlayerController.value.duration;
    
    // Ensure we don't seek beyond the video
    final newPosition = target.inMilliseconds < 0 
        ? Duration.zero 
        : (target > duration ? duration : target);
        
    _videoPlayerController.seekTo(newPosition);
    _showControlsTemporarily();
  }

  void _seekTo(double value) {
    if (_videoDuration.inMilliseconds > 0) {
      final newPosition = Duration(milliseconds: (value * _videoDuration.inMilliseconds).round());
      _videoPlayerController.seekTo(newPosition);
      setState(() {
        _currentPosition = newPosition;
      });
      _showControlsTemporarily();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return duration.inHours > 0 
        ? '$hours:$minutes:$seconds' 
        : '$minutes:$seconds';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetPreferredOrientations();
    _hideControlsTimer?.cancel();
    _videoPlayerController.removeListener(_videoPlayerListener);
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullScreen
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(widget.videoTitle ?? 'Video Player'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: _toggleFullScreen,
                    tooltip: 'Fullscreen',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share functionality to be implemented')),
                      );
                    },
                    tooltip: 'Share',
                  ),
                ],
              ),
        body: GestureDetector(
          onTap: _showControlsTemporarily,
          child: Stack(
            children: [
              // Center video player
              Center(
                child: _buildVideoPlayer(),
              ),
              
              // Custom overlay controls
              if (_showControls)
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.black38,
                    child: _buildCustomControls(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.accentColor,
        ),
      );
    }
    
    if (_isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // For "fullscreen" mode, we adjust the UI but don't rotate the device
    // unless explicitly allowed
    return AspectRatio(
      aspectRatio: _isFullScreen 
          ? _videoPlayerController.value.aspectRatio 
          : (_videoPlayerController.value.aspectRatio != 0.0
              ? _videoPlayerController.value.aspectRatio
              : 16 / 9),
      child: VideoPlayer(_videoPlayerController),
    );
  }

  Widget _buildCustomControls() {
    final double sliderValue = _videoDuration.inMilliseconds > 0 
        ? _currentPosition.inMilliseconds / _videoDuration.inMilliseconds
        : 0.0;
        
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top controls (only in fullscreen mode)
        _isFullScreen
            ? SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _toggleFullScreen,
                    ),
                    
                    // Video title if available
                    if (widget.videoTitle != null)
                      Expanded(
                        child: Text(
                          widget.videoTitle!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                    // Fullscreen exit button
                    IconButton(
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                      onPressed: _toggleFullScreen,
                    ),
                  ],
                ),
              )
            : const SizedBox(height: 0),

        // Center play/pause button
        Center(
          child: IconButton(
            iconSize: 64,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
        ),

        // Bottom control bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress & buffer bar
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Buffer progress
                    Container(
                      height: 3,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.white30,
                      child: FractionallySizedBox(
                        widthFactor: _bufferingProgress,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 3,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    
                    // Playback progress
                    SliderTheme(
                      data: SliderThemeData(
                        thumbColor: widget.accentColor,
                        activeTrackColor: widget.accentColor,
                        inactiveTrackColor: Colors.transparent,
                        trackHeight: 3.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                      ),
                      child: Slider(
                        value: sliderValue.clamp(0.0, 1.0),
                        onChanged: _seekTo,
                      ),
                    ),
                  ],
                ),
                
                // Time and controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Current position / total duration
                    Text(
                      '${_formatDuration(_currentPosition)} / ${_formatDuration(_videoDuration)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    
                    // Control buttons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10, color: Colors.white),
                          onPressed: () => _seekRelative(const Duration(seconds: -10)),
                        ),
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10, color: Colors.white),
                          onPressed: () => _seekRelative(const Duration(seconds: 10)),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: Colors.white
                          ),
                          onPressed: _toggleFullScreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Example usage:
// Navigator.of(context).push(
//   VideoViewerScreen.route(
//     videoUrl: 'https://example.com/sample.mp4',
//     videoTitle: 'Sample Video',
//     accentColor: Colors.red,
//     allowOrientationChanges: false, // This prevents auto-rotation
//   ),
// );