import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPreviewWidget extends StatefulWidget {
  final File videoFile;
  final VoidCallback? onRetry;

  const VideoPreviewWidget({
    Key? key,
    required this.videoFile,
    this.onRetry,
  }) : super(key: key);

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isInitialized = false;
        _hasError = false;
        _errorMessage = '';
      });

      _videoPlayerController = VideoPlayerController.file(widget.videoFile);
      
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey.withOpacity(0.5),
          bufferedColor: Theme.of(context).primaryColor.withOpacity(0.5),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load video',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Select Another Video'),
                  ),
                ],
              ],
            ),
          );
        },
      );
      
      setState(() {
        _isInitialized = true;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
      });
      
      debugPrint('Error initializing video player: $error');
    }
  }
  
  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Select Another Video'),
              ),
            ],
          ],
        ),
      );
    }
    
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }
    
    return AspectRatio(
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}