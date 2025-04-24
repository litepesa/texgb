import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/status/widgets/status_media_viewer.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class StatusDetailScreen extends StatefulWidget {
  final StatusModel status;
  final bool isMyStatus;

  const StatusDetailScreen({
    Key? key,
    required this.status,
    required this.isMyStatus,
  }) : super(key: key);

  @override
  State<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends State<StatusDetailScreen> with SingleTickerProviderStateMixin {
  // Use this controller to control the progress bar animation
  late AnimationController _progressController;
  
  // Page controller for horizontal swiping between status items
  late PageController _pageController;
  
  // Index of the currently displayed status item
  int _currentIndex = 0;
  
  // Timer for auto-advancing status
  Timer? _timer;
  
  // Status item durations (videos will use their actual duration)
  final Duration _imageDuration = const Duration(seconds: 5);
  
  // Flag to pause status when user long presses
  bool _isPaused = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize PageController for swiping
    _pageController = PageController();
    
    // Initialize AnimationController for the progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: _imageDuration,
    );
    
    // Set up status view tracking
    _markCurrentStatusAsViewed();
    
    // Start timer for auto-advance
    _startStatusTimer();
    
    // Listen for animation completion
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextStatus();
      }
    });
    
    // Start the animation
    _progressController.forward();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _startStatusTimer() {
    // Cancel any existing timer
    _timer?.cancel();
    
    // Set the appropriate duration based on the status type
    final currentItem = widget.status.items[_currentIndex];
    Duration duration;
    
    switch (currentItem.type) {
      case StatusType.image:
      case StatusType.text:
        duration = _imageDuration;
        break;
      case StatusType.video:
        // Videos will control their own duration
        // Use a longer default for safety
        duration = const Duration(seconds: 30);
        break;
    }
    
    // Reset and start the animation
    _progressController.duration = duration;
    _progressController.forward(from: 0.0);
  }
  
  void _markCurrentStatusAsViewed() {
    if (widget.isMyStatus) return; // Don't mark own status as viewed
    
    final currentItem = widget.status.items[_currentIndex];
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    // Mark status as viewed
    context.read<StatusProvider>().markStatusAsViewed(
      statusOwnerId: widget.status.uid,
      statusItemId: currentItem.itemId,
      viewerId: currentUser.uid,
    );
  }
  
  void _goToNextStatus() {
    if (_currentIndex < widget.status.items.length - 1) {
      // Go to next item
      setState(() {
        _currentIndex++;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      
      // Mark as viewed and restart timer
      _markCurrentStatusAsViewed();
      _startStatusTimer();
    } else {
      // No more items, close the screen
      Navigator.of(context).pop();
    }
  }
  
  void _goToPreviousStatus() {
    if (_currentIndex > 0) {
      // Go to previous item
      setState(() {
        _currentIndex--;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      
      // Mark as viewed and restart timer
      _markCurrentStatusAsViewed();
      _startStatusTimer();
    }
  }
  
  void _onHorizontalDragEnd(DragEndDetails details) {
    // Detect swipe direction
    if (details.primaryVelocity! > 0) {
      // Swiped right to left (go to previous)
      _goToPreviousStatus();
    } else if (details.primaryVelocity! < 0) {
      // Swiped left to right (go to next)
      _goToNextStatus();
    }
  }
  
  void _onLongPressStart(LongPressStartDetails details) {
    // Pause the timer on long press
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
  }
  
  void _onLongPressEnd(LongPressEndDetails details) {
    // Resume the timer when long press ends
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
  }
  
  void _onTap(TapUpDetails details) {
    // Detect tap position for navigation
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.localPosition.dx;
    
    if (tapPosition < screenWidth / 3) {
      // Tapped on left third (go to previous)
      _goToPreviousStatus();
    } else if (tapPosition > (screenWidth * 2 / 3)) {
      // Tapped on right third (go to next)
      _goToNextStatus();
    }
  }
  
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Mark as viewed and restart timer
    _markCurrentStatusAsViewed();
    _startStatusTimer();
  }
  
  // Delete current status item (only for user's own status)
  void _deleteCurrentStatus() async {
    if (!widget.isMyStatus) return;
    
    final currentItem = widget.status.items[_currentIndex];
    final statusProvider = context.read<StatusProvider>();
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    await statusProvider.deleteStatusItem(
      userId: currentUser.uid,
      itemId: currentItem.itemId,
      onSuccess: () {
        if (widget.status.items.length <= 1) {
          // If this was the only status item, return to status screen
          Navigator.of(context).pop();
        } else if (_currentIndex >= widget.status.items.length - 1) {
          // If this was the last item, go to previous
          _goToPreviousStatus();
        } else {
          // Otherwise refresh the current page
          _startStatusTimer();
        }
        showSnackBar(context, 'Status deleted');
      },
      onError: (error) {
        showSnackBar(context, 'Error deleting status: $error');
      },
    );
  }
  
  Future<void> _showReactionPicker() async {
    if (widget.isMyStatus) return; // Can't react to own status
    
    // Pause the timer
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    
    // Show reactions
    final statusProvider = context.read<StatusProvider>();
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final currentItem = widget.status.items[_currentIndex];
    
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    
    final reaction = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor!.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: modernTheme.textSecondaryColor!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'React to status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: modernTheme.textColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReactionButton('👍'),
                  _buildReactionButton('❤️'),
                  _buildReactionButton('😂'),
                  _buildReactionButton('😮'),
                  _buildReactionButton('😢'),
                  _buildReactionButton('🙏'),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    
    // Resume the timer
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
    
    // Send reaction if one was chosen
    if (reaction != null) {
      await statusProvider.addReactionToStatus(
        statusOwnerId: widget.status.uid,
        statusItemId: currentItem.itemId,
        reactorId: currentUser.uid,
        reactorName: currentUser.name,
        reaction: reaction,
      );
    }
  }
  
  Widget _buildReactionButton(String emoji) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, emoji),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapUp: _onTap,
          child: Stack(
            children: [
              // Status content
              GestureDetector(
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onLongPressStart: _onLongPressStart,
                onLongPressEnd: _onLongPressEnd,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.status.items.length,
                  onPageChanged: _onPageChanged,
                  physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                  itemBuilder: (context, index) {
                    final statusItem = widget.status.items[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Status media content
                        StatusMediaViewer(
                          statusItem: statusItem,
                          isPaused: _isPaused,
                          onDurationChanged: (duration) {
                            // Update controller duration for videos
                            if (statusItem.type == StatusType.video && !_isPaused) {
                              setState(() {
                                _progressController.duration = duration;
                              });
                              _progressController.forward(from: 0.0);
                            }
                          },
                        ),
                        
                        // Semi-transparent overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        
                        // Caption at bottom (if any)
                        if (statusItem.caption != null && statusItem.caption!.isNotEmpty)
                          Positioned(
                            bottom: 80,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                statusItem.caption!,
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
                  },
                ),
              ),
              
              // Progress bars
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: List.generate(
                    widget.status.items.length,
                    (index) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: index == _currentIndex
                            ? AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    widthFactor: _progressController.value,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : FractionallySizedBox(
                                widthFactor: index < _currentIndex ? 1.0 : 0.0,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Header (user info)
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: CachedNetworkImageProvider(widget.status.userImage),
                    ),
                    const SizedBox(width: 8),
                    
                    // User name and timestamp
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.status.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getTimeAgo(widget.status.items[_currentIndex].timestamp),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Action buttons at bottom
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Delete button (only for own status)
                    if (widget.isMyStatus)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: _deleteCurrentStatus,
                      )
                    else
                      const SizedBox(width: 48), // Placeholder for layout
                    
                    // View count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
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
                            '${widget.status.items[_currentIndex].viewedBy.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // React button (for viewing others' status)
                    if (!widget.isMyStatus)
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions, color: Colors.white),
                        onPressed: _showReactionPicker,
                      )
                    else
                      const SizedBox(width: 48), // Placeholder for layout
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return 'Yesterday';
    }
  }
}