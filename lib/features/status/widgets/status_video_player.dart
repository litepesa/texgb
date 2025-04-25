// lib/features/status/widgets/status_video_player.dart

import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
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

class _StatusVideoPlayerState extends State<StatusVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant StatusVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      await _videoPlayerController.initialize();
      
      // Create ChewieController
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Error loading video',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
        showControlsOnInitialize: false,
        showOptions: false,
        allowFullScreen: false,
        allowMuting: false,
        hideControlsTimer: const Duration(seconds: 2),
        placeholder: Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: context.modernTheme.primaryColor,
            ),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: context.modernTheme.primaryColor!,
          handleColor: context.modernTheme.primaryColor!,
          backgroundColor: Colors.grey[700]!,
          bufferedColor: Colors.grey[500]!,
        ),
      );
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the status tab is visible to control video play/pause
    final isStatusTabVisible = context.select<StatusProvider, bool>(
      (provider) => provider.isStatusTabVisible,
    );
    
    // Pause video when status tab is not visible
    if (_isInitialized && !isStatusTabVisible && _videoPlayerController.value.isPlaying) {
      _videoPlayerController.pause();
    }
    
    // Resume video when status tab becomes visible again
    if (_isInitialized && isStatusTabVisible && 
        !_videoPlayerController.value.isPlaying && 
        widget.autoPlay) {
      _videoPlayerController.play();
    }
    
    if (_isError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 48),
              SizedBox(height: 8),
              Text(
                'Error loading video',
                style: TextStyle(color: Colors.white),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            color: context.modernTheme.primaryColor,
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        Chewie(controller: _chewieController!),
        
        // Double-tap gesture detector for 'like' action
        Positioned.fill(
          child: GestureDetector(
            onDoubleTap: () {
              // Trigger double-tap like animation
              _showLikeAnimation();
              
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
            },
          ),
        ),
      ],
    );
  }

  // Shows a heart animation when double-tapped
  void _showLikeAnimation() {
    // Implementation for like animation would go here
    // This could be a custom overlay that shows a heart icon
    // that grows and fades away
  }

  void _disposeControllers() {
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
    _videoPlayerController.dispose();
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
}