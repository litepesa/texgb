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
  Timer? _hideControlsTimer;
  bool _showControls = true;
  final Duration _controlsTimeout = const Duration(seconds: 2); // Reduced from 3 to 2 seconds
  bool _isPlaying = false;
  bool _isMuted = false;
  Duration _currentPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Force portrait orientation always
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _initializePlayer();
    _startHideControlsTimer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      
      // Add listeners
      _videoPlayerController.addListener(_videoPlayerListener);
      
      await _videoPlayerController.initialize();
      
      // Enable looping
      _videoPlayerController.setLooping(true);
      
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
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Always make sure we're in portrait when returning to the app
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
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
  
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoPlayerController.setVolume(_isMuted ? 0.0 : 1.0);
    });
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

  // Format duration to mm:ss or hh:mm:ss
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
    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    _hideControlsTimer?.cancel();
    _videoPlayerController.removeListener(_videoPlayerListener);
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showControlsTemporarily,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player centered
            Center(
              child: _buildVideoPlayer(),
            ),
            
            // Minimalist controls overlay
            if (_showControls)
              _buildMinimalistControls(),
          ],
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
    
    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio != 0.0
          ? _videoPlayerController.value.aspectRatio
          : 16 / 9,
      child: VideoPlayer(_videoPlayerController),
    );
  }

  Widget _buildMinimalistControls() {
    final double sliderValue = _videoDuration.inMilliseconds > 0 
        ? _currentPosition.inMilliseconds / _videoDuration.inMilliseconds
        : 0.0;
        
    return Stack(
      children: [
        // Back button - top left
        Positioned(
          top: 20,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        
        // Mute/unmute button - top right
        Positioned(
          top: 20,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
              onPressed: _toggleMute,
            ),
          ),
        ),
        
        // Centered play/pause
        Center(
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        
        // Timer display above progress bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Current position
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(_currentPosition),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                // Total duration
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(_videoDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Minimal progress bar at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SliderTheme(
              data: SliderThemeData(
                thumbColor: widget.accentColor,
                activeTrackColor: widget.accentColor,
                inactiveTrackColor: Colors.white30,
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
              ),
              child: Slider(
                value: sliderValue.clamp(0.0, 1.0),
                onChanged: (value) {
                  if (_videoDuration.inMilliseconds > 0) {
                    final newPosition = Duration(milliseconds: (value * _videoDuration.inMilliseconds).round());
                    _videoPlayerController.seekTo(newPosition);
                    setState(() {
                      _currentPosition = newPosition;
                    });
                    _showControlsTemporarily();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}