import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/status_text_content.dart';
import 'package:textgb/features/status/widgets/status_video_player.dart';
import 'package:textgb/models/message_reply_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/chat_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusDetailScreen extends StatefulWidget {
  final StatusModel status;
  final List<StatusModel> statuses;
  final int initialIndex;

  const StatusDetailScreen({
    Key? key,
    required this.status,
    required this.statuses,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends State<StatusDetailScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimController;
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isShowingActions = true;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Initialize animation controller for the progress indicator
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // View time for each status
    );
    
    _progressAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStatus();
      }
    });
    
    // Register status as viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markCurrentStatusAsViewed();
      _startProgressAnimation();
    });
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Start with actions visible
    _isShowingActions = true;
    _startActionTimeout();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    super.dispose();
  }
  
  // Mark status as viewed in provider
  void _markCurrentStatusAsViewed() {
    if (_currentIndex < widget.statuses.length) {
      final status = widget.statuses[_currentIndex];
      context.read<StatusProvider>().markStatusAsViewed(status);
    }
  }
  
  // Start the progress animation
  void _startProgressAnimation() {
    _progressAnimController.forward(from: 0.0);
  }
  
  // Reset and restart the progress animation
  void _resetProgressAnimation() {
    _progressAnimController.reset();
    _progressAnimController.forward();
  }
  
  // Move to next status
  void _nextStatus() {
    if (_currentIndex < widget.statuses.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last status, go back to previous screen
      Navigator.pop(context);
    }
  }
  
  // Move to previous status
  void _previousStatus() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // Toggle pause state
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      
      if (_isPaused) {
        _progressAnimController.stop();
      } else {
        _progressAnimController.forward();
      }
    });
  }
  
  // Auto-hide actions after a delay
  void _startActionTimeout() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isShowingActions && !_isPaused) {
        setState(() {
          _isShowingActions = false;
        });
      }
    });
  }
  
  // Toggle showing actions
  void _toggleActions() {
    setState(() {
      _isShowingActions = !_isShowingActions;
      
      if (_isShowingActions) {
        _startActionTimeout();
      }
    });
  }
  
  // Reply to status - start a chat with context
  void _replyToStatus() {
    final status = widget.statuses[_currentIndex];
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    // Create a message reply model to use in chat
    final messageReply = MessageReplyModel(
      message: status.type == StatusType.text 
          ? status.text 
          : status.type == StatusType.image
              ? 'Status image'
              : 'Status video',
      senderUID: status.uid,
      senderName: status.userName,
      senderImage: status.userImage,
      messageType: status.type == StatusType.text 
          ? MessageEnum.text 
          : status.type == StatusType.image
              ? MessageEnum.image
              : MessageEnum.video,
      isMe: status.uid == currentUser.uid,
    );
    
    // Set message reply in chat provider
    context.read<ChatProvider>().setMessageReplyModel(messageReply);
    
    // Navigate to chat screen
    Navigator.pushNamed(
      context,
      Constants.chatScreen,
      arguments: {
        Constants.contactUID: status.uid,
        Constants.contactName: status.userName,
        Constants.contactImage: status.userImage,
        Constants.groupId: '',
      },
    );
  }
  
  // Handle like action
  void _toggleLike() {
    if (_currentIndex < widget.statuses.length) {
      final status = widget.statuses[_currentIndex];
      context.read<StatusProvider>().toggleStatusLike(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.watch<StatusProvider>();
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleActions,
        onLongPress: _togglePause,
        onLongPressEnd: (_) => _togglePause(),
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            // Swipe right - go to previous status
            _previousStatus();
          } else if (details.primaryVelocity! < 0) {
            // Swipe left - go to next status
            _nextStatus();
          }
        },
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping
          itemCount: widget.statuses.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
              _isPaused = false;
              _isShowingActions = true;
            });
            _resetProgressAnimation();
            _markCurrentStatusAsViewed();
            _startActionTimeout();
          },
          itemBuilder: (context, index) {
            final status = widget.statuses[index];
            
            return Stack(
              fit: StackFit.expand,
              children: [
                // Status content
                _buildStatusContent(status),
                
                // Tap areas for navigation
                Row(
                  children: [
                    // Left third - previous status
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          _previousStatus();
                          _toggleActions();
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    
                    // Middle third - toggle actions
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _toggleActions,
                        behavior: HitTestBehavior.translucent,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    
                    // Right third - next status
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          _nextStatus();
                          _toggleActions();
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
                
                // Progress indicator
                if (_isShowingActions)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: List.generate(
                        widget.statuses.length,
                        (i) => Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i < _currentIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                            child: i == _currentIndex
                                ? AnimatedBuilder(
                                    animation: _progressAnimController,
                                    builder: (context, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _progressAnimController.value,
                                        child: Container(color: Colors.white),
                                      );
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // User info and actions (top)
                if (_isShowingActions)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        // Profile picture and name
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: CachedNetworkImageProvider(status.userImage),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  timeago.format(status.createdAt),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Action buttons
                        IconButton(
                          icon: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                          ),
                          onPressed: _togglePause,
                        ),
                        
                        // Close button
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                
                // Bottom actions bar
                if (_isShowingActions)
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Status info (views, likes)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // View count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.remove_red_eye,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${status.viewCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Like count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    status.isLikedBy(currentUser.uid) 
                                        ? Icons.favorite 
                                        : Icons.favorite_border,
                                    color: status.isLikedBy(currentUser.uid)
                                        ? Colors.red
                                        : Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${status.likeCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Reply button
                            GestureDetector(
                              onTap: _replyToStatus,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.reply,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Reply',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Like button
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      status.isLikedBy(currentUser.uid)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: status.isLikedBy(currentUser.uid)
                                          ? Colors.red
                                          : Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Like',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Delete button (only for current user's status)
                            if (status.uid == currentUser.uid)
                              GestureDetector(
                                onTap: () {
                                  // Confirm deletion
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Status'),
                                      content: const Text('Are you sure you want to delete this status?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('CANCEL'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context); // Close dialog
                                            context.read<StatusProvider>().deleteStatus(status);
                                            Navigator.pop(context); // Go back to previous screen
                                          },
                                          child: const Text('DELETE'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  // Build the status content based on type
  Widget _buildStatusContent(StatusModel status) {
    switch (status.type) {
      case StatusType.text:
        return StatusTextContent(
          text: status.text,
          backgroundInfo: status.backgroundInfo,
        );
      case StatusType.image:
        return CachedNetworkImage(
          imageUrl: status.mediaUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 48,
            ),
          ),
        );
      case StatusType.video:
        return StatusVideoPlayer(
          videoUrl: status.mediaUrl,
          isPaused: _isPaused,
        );
      default:
        return const Center(
          child: Text(
            'Unsupported status type',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }
}