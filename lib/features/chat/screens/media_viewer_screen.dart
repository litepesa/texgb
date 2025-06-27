import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:intl/intl.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final MessageModel message;
  final UserModel sender;
  final List<MessageModel>? mediaMessages; // Optional list of media messages for gallery view

  const MediaViewerScreen({
    Key? key,
    required this.message,
    required this.sender,
    this.mediaMessages,
  }) : super(key: key);

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  // Controllers for video playback
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  // For gallery view
  late PageController _pageController;
  late int _currentIndex;
  bool _isFullScreen = false;
  bool _isControlsVisible = true;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize for gallery view if mediaMessages is provided
    if (widget.mediaMessages != null && widget.mediaMessages!.isNotEmpty) {
      _currentIndex = widget.mediaMessages!.indexWhere(
        (msg) => msg.messageId == widget.message.messageId
      );
      if (_currentIndex < 0) _currentIndex = 0;
      
      _pageController = PageController(initialPage: _currentIndex);
    } else {
      _currentIndex = 0;
      _pageController = PageController();
    }
    
    // Initialize media player based on message type
    _initializeMedia(widget.message);
    
    // Hide status bar for more immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: [SystemUiOverlay.bottom]
    );
  }
  
  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _pageController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]
    );
    
    super.dispose();
  }
  
  Future<void> _initializeMedia(MessageModel message) async {
    if (message.messageType == MessageEnum.video) {
      await _initializeVideoPlayer(message.message);
    }
  }
  
  Future<void> _initializeVideoPlayer(String videoUrl) async {
    // Dispose previous controllers if they exist
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    
    // Create new video player controller
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    
    try {
      // Initialize the controller and update state when done
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: false,
        placeholder: Center(
          child: CircularProgressIndicator(
            color: context.modernTheme.primaryColor,
          ),
        ),
      );
      
      // Update state to rebuild widget with initialized controllers
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      // Show error in UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load video: $e')),
      );
    }
  }
  
  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }
  
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
        );
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.bottom],
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _isControlsVisible && !_isFullScreen
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.4),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                widget.sender.name,
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Implement download functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download feature coming soon')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // TODO: Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon')),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                  onPressed: _toggleFullScreen,
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: widget.mediaMessages != null && widget.mediaMessages!.length > 1
            ? _buildGalleryView()
            : _buildSingleMediaView(widget.message),
      ),
      bottomNavigationBar: _isControlsVisible && !_isFullScreen && widget.mediaMessages != null && widget.mediaMessages!.length > 1
          ? _buildBottomInfoBar()
          : null,
    );
  }
  
  Widget _buildSingleMediaView(MessageModel message) {
    if (message.messageType == MessageEnum.image) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: message.message,
            fit: BoxFit.contain,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                color: context.modernTheme.primaryColor,
              ),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error, color: Colors.white, size: 50),
            ),
          ),
        ),
      );
    } else if (message.messageType == MessageEnum.video) {
      if (_chewieController != null && _videoPlayerController!.value.isInitialized) {
        return Center(
          child: Chewie(controller: _chewieController!),
        );
      } else {
        return Center(
          child: CircularProgressIndicator(
            color: context.modernTheme.primaryColor,
          ),
        );
      }
    } else {
      return const Center(
        child: Text(
          'Unsupported media type',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }
  
  Widget _buildGalleryView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.mediaMessages!.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
          // Initialize the new media if it's a video
          if (widget.mediaMessages![index].messageType == MessageEnum.video) {
            _initializeVideoPlayer(widget.mediaMessages![index].message);
          } else {
            // If it's not a video, dispose any existing video controllers
            _videoPlayerController?.pause();
          }
        });
      },
      itemBuilder: (context, index) {
        return _buildSingleMediaView(widget.mediaMessages![index]);
      },
    );
  }
  
  Widget _buildBottomInfoBar() {
    final message = widget.mediaMessages![_currentIndex];
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(message.timeSent),
    );
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    
    return Container(
      color: Colors.black.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentIndex + 1} of ${widget.mediaMessages!.length}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                dateFormat.format(dateTime),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          if (widget.mediaMessages!.length > 1)
            Container(
              height: 50,
              margin: const EdgeInsets.only(top: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.mediaMessages!.length,
                itemBuilder: (context, index) {
                  final msg = widget.mediaMessages![index];
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: index == _currentIndex
                            ? Border.all(color: context.modernTheme.primaryColor!, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: msg.messageType == MessageEnum.image
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: CachedNetworkImage(
                                imageUrl: msg.message,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.error, color: Colors.white, size: 20),
                                ),
                              ),
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.videocam, color: Colors.white70),
                                  ),
                                ),
                                if (msg.messageType == MessageEnum.video)
                                  const Center(
                                    child: Icon(Icons.play_circle_outline, color: Colors.white, size: 20),
                                  ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}