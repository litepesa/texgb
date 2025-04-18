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
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isFullScreen = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize player but don't change orientation yet
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isFullScreen) {
      _setPreferredOrientations(true);
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      
      // Listen for errors
      _videoPlayerController.addListener(_videoPlayerListener);
      
      await _videoPlayerController.initialize();
      
      // Create Chewie controller with custom UI options
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: Center(
          child: CircularProgressIndicator(color: widget.accentColor),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: widget.accentColor,
          handleColor: widget.accentColor,
          bufferedColor: Colors.grey.withOpacity(0.5),
          backgroundColor: Colors.grey.withOpacity(0.3),
        ),
        customControls: const CupertinoControls(
          backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: Color.fromARGB(255, 255, 255, 255),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error: $errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initializePlayer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: widget.accentColor,
                  ),
                ),
              ],
            ),
          );
        },
      );
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to initialize video: $error';
      });
      debugPrint(_errorMessage);
    }
  }

  void _videoPlayerListener() {
    // Check for player errors
    if (_videoPlayerController.value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Video playback error: ${_videoPlayerController.value.errorDescription}';
      });
      debugPrint(_errorMessage);
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
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      setState(() => _isFullScreen = false);
    }
  }

  void _resetPreferredOrientations() {
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _toggleFullScreen() {
    _setPreferredOrientations(!_isFullScreen);
  }

  void _shareVideo() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing video...')),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetPreferredOrientations();
    _hideControlsTimer?.cancel();
    _videoPlayerController.removeListener(_videoPlayerListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
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
                    onPressed: _shareVideo,
                    tooltip: 'Share',
                  ),
                ],
              ),
        body: Center(
          child: _buildVideoPlayer(),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.accentColor,
        ),
      );
    }
    
    if (_hasError) {
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
              Text(
                _errorMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initializePlayer,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: widget.accentColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized || _chewieController == null) {
      return const Center(
        child: Text(
          'Initializing player...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}