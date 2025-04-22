import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoViewerScreen extends StatefulWidget {
  final String videoUrl;
  final String? videoTitle;
  final Color accentColor;

  const VideoViewerScreen({
    Key? key,
    required this.videoUrl,
    this.videoTitle,
    required this.accentColor,
  }) : super(key: key);

  static Route route({
    required String videoUrl,
    String? videoTitle,
    required Color accentColor,
  }) {
    return MaterialPageRoute(
      builder: (context) => VideoViewerScreen(
        videoUrl: videoUrl,
        videoTitle: videoTitle,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        showOptions: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        placeholder: Center(
          child: CircularProgressIndicator(
            color: widget.accentColor,
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: widget.accentColor,
          handleColor: widget.accentColor,
          backgroundColor: Colors.grey.withOpacity(0.5),
          bufferedColor: widget.accentColor.withOpacity(0.5),
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = error.toString();
      });
      
      debugPrint('Error initializing video player: $error');
    }
  }
  
  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.videoTitle ?? 'Video',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.accentColor,
        ),
      );
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializePlayer,
              icon: const Icon(Icons.refresh),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
              ),
              label: const Text('Retry'),
            )
          ],
        ),
      );
    }
    
    return Center(
      child: Chewie(controller: _chewieController!),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String? caption;

  const ImageViewerScreen({
    Key? key,
    required this.imageUrl,
    this.caption,
  }) : super(key: key);

  static Route route({
    required String imageUrl,
    String? caption,
  }) {
    return MaterialPageRoute(
      builder: (context) => ImageViewerScreen(
        imageUrl: imageUrl,
        caption: caption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: caption != null && caption!.isNotEmpty
            ? Text(
                caption!,
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.network(
            imageUrl,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}