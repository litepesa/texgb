// lib/features/status/screens/status_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/models/message_reply_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class StatusViewerScreen extends StatefulWidget {
  final String userId;
  
  const StatusViewerScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  
  List<StatusPostModel> _statuses = [];
  int _currentIndex = 0;
  bool _isPaused = false;
  
  // Flag to track if we should continue to the next status automatically
  bool _shouldContinue = true;
  
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    
    // Set system overlay style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    // Create animation controller for progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Default duration
    );
    
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _shouldContinue) {
        _goToNextStatus();
      }
    });
    
    // Setup focus listener for reply field
    _replyFocusNode.addListener(_handleFocusChange);
    
    // Load statuses
    _loadStatuses();
  }
  
  void _handleFocusChange() {
    // Pause progress and video when reply field is focused
    if (_replyFocusNode.hasFocus) {
      _pauseStatus();
    } else {
      _resumeStatus();
    }
  }
  
  void _loadStatuses() {
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    
    if (widget.userId == Provider.of<AuthenticationProvider>(context, listen: false).userModel?.uid) {
      // Viewing own statuses
      _statuses = statusProvider.myStatuses;
    } else {
      // Viewing contact's statuses
      _statuses = statusProvider.userStatusMap[widget.userId] ?? [];
    }
    
    if (_statuses.isNotEmpty) {
      // Mark first status as viewed
      _initializeStatus(0);
    }
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }
  
  void _initializeStatus(int index) {
    if (index < 0 || index >= _statuses.length) return;
    
    // Reset controllers
    _disposeVideoController();
    
    // Mark as viewed
    final status = _statuses[index];
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser != null && widget.userId != currentUser.uid) {
      Provider.of<StatusProvider>(context, listen: false).viewStatus(
        statusId: status.statusId,
        viewerUid: currentUser.uid,
      );
    }
    
    // Set progress controller duration based on type
    Duration statusDuration;
    if (status.type == StatusType.video) {
      // Video duration will be set after video is initialized
      statusDuration = const Duration(seconds: 5);
    } else if (status.type == StatusType.text) {
      // Text statuses get more time to read
      statusDuration = const Duration(seconds: 6);
    } else {
      // Default duration for images
      statusDuration = const Duration(seconds: 5);
    }
    
    _progressController.duration = statusDuration;
    
    // Initialize video if needed
    if (status.type == StatusType.video && status.mediaUrls.isNotEmpty) {
      _initializeVideoController(status.mediaUrls.first);
    } else {
      // Start progress for non-video types
      _startProgress();
    }
  }
  
  void _initializeVideoController(String videoUrl) async {
    _videoController = VideoPlayerController.network(videoUrl);
    
    try {
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {});
        
        // Set progress controller duration to match video
        _progressController.duration = _videoController!.value.duration;
        
        // Play video and start progress
        _videoController!.play();
        _startProgress();
      }
    } catch (e) {
      print('Error initializing video: $e');
      // If video fails, use default duration and continue
      _startProgress();
    }
  }
  
  void _disposeVideoController() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
    }
  }
  
  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }
  
  void _pauseStatus() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    _videoController?.pause();
  }
  
  void _resumeStatus() {
    if (!_replyFocusNode.hasFocus) {
      setState(() {
        _isPaused = false;
      });
      _progressController.forward();
      _videoController?.play();
    }
  }
  
  void _goToPreviousStatus() {
    if (_currentIndex > 0) {
      _shouldContinue = false;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _goToNextStatus() {
    if (_currentIndex < _statuses.length - 1) {
      _shouldContinue = false;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // No more statuses, exit the viewer
      Navigator.of(context).pop();
    }
  }
  
  // Send a reply as a chat message
  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;
    
    final status = _statuses[_currentIndex];
    
    try {
      // Create a message reply model with the status content as the replied message
      final messageReply = MessageReplyModel(
        message: status.caption.isNotEmpty ? status.caption : "(${status.type.name} status)",
        senderUID: status.uid,
        senderName: status.username,
        senderImage: status.userImage,
        messageType: status.type.toMessageEnum(),
        isMe: status.uid == currentUser.uid,
      );
      
      // Set the message reply in chat provider
      Provider.of<ChatProvider>(context, listen: false).setMessageReplyModel(messageReply);
      
      // Send the text message with the status as reply context
      await Provider.of<ChatProvider>(context, listen: false).sendTextMessage(
        sender: currentUser,
        contactUID: status.uid,
        contactName: status.username,
        contactImage: status.userImage,
        message: _replyController.text.trim(),
        messageType: MessageEnum.text,
        groupId: '', // Not a group message
        onSucess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reply sent'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send reply: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
      
      // Reset the message reply
      Provider.of<ChatProvider>(context, listen: false).setMessageReplyModel(null);
      
      _replyController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reply: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    if (_statuses.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No status updates found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          // Divide screen into three parts for navigation
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _goToPreviousStatus();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _goToNextStatus();
          } else {
            // Middle tap toggles pause/play
            if (_isPaused) {
              _resumeStatus();
            } else {
              _pauseStatus();
            }
          }
        },
        onLongPress: () {
          // Long press to pause
          _pauseStatus();
        },
        onLongPressUp: () {
          // Resume on long press release
          _resumeStatus();
        },
        child: Stack(
          children: [
            // Status content
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swiping
              itemCount: _statuses.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _initializeStatus(index);
                _shouldContinue = true;
              },
              itemBuilder: (context, index) {
                final status = _statuses[index];
                return _buildStatusContent(status);
              },
            ),
            
            // Header with progress indicators
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Column(
                  children: [
                    // Progress bars
                    Row(
                      children: List.generate(
                        _statuses.length,
                        (index) => Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: LinearProgressIndicator(
                              value: index < _currentIndex 
                                  ? 1.0 
                                  : (index == _currentIndex 
                                      ? _progressController.value 
                                      : 0.0),
                              backgroundColor: Colors.grey.withOpacity(0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // User info
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _statuses[_currentIndex].userImage.isNotEmpty
                                ? CachedNetworkImageProvider(_statuses[_currentIndex].userImage)
                                : AssetImage(AssetsManager.userImage) as ImageProvider,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _statuses[_currentIndex].username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(_statuses[_currentIndex].createdAt),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Reply field at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).viewInsets.bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        focusNode: _replyFocusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Reply to this status...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _sendReply,
                    ),
                  ],
                ),
              ),
            ),
            
            // Play/pause indicator
            if (_isPaused)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusContent(StatusPostModel status) {
    switch (status.type) {
      case StatusType.video:
        return _buildVideoStatus(status);
      case StatusType.text:
        return _buildTextStatus(status);
      case StatusType.image:
      default:
        return _buildImageStatus(status);
    }
  }
  
  Widget _buildImageStatus(StatusPostModel status) {
    if (status.mediaUrls.isEmpty) {
      return Container(
        color: Colors.blue, // Fallback color for empty image status
        child: Center(
          child: Text(
            status.caption.isNotEmpty ? status.caption : 'No content',
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        CachedNetworkImage(
          imageUrl: status.mediaUrls.first,
          fit: BoxFit.contain,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
          errorWidget: (context, url, error) => Center(
            child: Icon(Icons.error, color: Colors.white, size: 42),
          ),
        ),
        
        // Caption overlay at bottom
        if (status.caption.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 70, // Leave space for reply field
            child: Container(
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
                status.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildVideoStatus(StatusPostModel status) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
        
        // Caption overlay at bottom
        if (status.caption.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 70, // Leave space for reply field
            child: Container(
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
                status.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildTextStatus(StatusPostModel status) {
    return Container(
      color: Colors.blue, // Default background color
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          status.caption,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return 'Yesterday';
    }
  }
}