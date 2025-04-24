import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/status/status_reply_handler.dart';
import 'package:textgb/features/status/widgets/status_media_viewer.dart';
import 'package:textgb/features/status/widgets/status_response_widget.dart';
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
  
  // Flag to track if we're viewing the reply UI
  bool _isShowingReply = false;
  
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
    if (_isShowingReply) return; // Don't advance while showing reply UI
    
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
    if (_isShowingReply) return; // Don't go back while showing reply UI
    
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
    if (_isShowingReply) return; // Don't respond to swipes while showing reply UI
    
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
    if (_isShowingReply) return; // Don't respond to long press when reply UI is showing
    
    // Pause the timer on long press
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
  }
  
  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isShowingReply) return; // Don't respond when reply UI is showing
    
    // Resume the timer when long press ends
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
  }
  
  void _onTap(TapUpDetails details) {
    if (_isShowingReply) return; // Don't respond when reply UI is showing
    
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
  
  // Show reply input
  void _showReplyInput() async {
    if (widget.isMyStatus) return; // Can't reply to own status
    
    // Pause the timer
    setState(() {
      _isPaused = true;
      _isShowingReply = true;
    });
    _progressController.stop();
    
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    // Show bottom sheet with reply input
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatusResponseWidget(
          statusItem: widget.status.items[_currentIndex],
          status: widget.status,
          onSuccess: () {
            // After successful reply, automatically navigate to chat in StatusReplyHandler
          },
        ),
      ),
    );
    
    // Resume the timer
    setState(() {
      _isPaused = false;
      _isShowingReply = false;
    });
    _progressController.forward();
  }
  
  void _shareStatus() {
    final currentItem = widget.status.items[_currentIndex];
    
    // Pause the timer
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    
    // Show sharing options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShareOptions(currentItem),
    ).then((_) {
      // Resume the timer
      setState(() {
        _isPaused = false;
      });
      _progressController.forward();
    });
  }
  
  Widget _buildShareOptions(StatusItemModel statusItem) {
    final modernTheme = context.modernTheme;
    final surface = modernTheme.surfaceColor!;
    final textColor = modernTheme.textColor!;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            'Share Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Share options
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat, color: modernTheme.primaryColor),
            ),
            title: const Text('Send in Chat'),
            onTap: () {
              Navigator.pop(context);
              showSnackBar(context, 'Forward to chat coming soon');
            },
          ),
          
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share, color: Colors.green),
            ),
            title: const Text('Share Externally'),
            onTap: () {
              Navigator.pop(context);
              showSnackBar(context, 'External sharing coming soon');
            },
          ),
          
          const SizedBox(height: 10),
        ],
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
                    
                    // Share button
                    if (!widget.isMyStatus)
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: _shareStatus,
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
                      // Reply button for other people's status
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          onTap: _showReplyInput,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.reply,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Reply',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // View count with viewers indicator
                    GestureDetector(
                      onTap: widget.isMyStatus ? _showViewersDialog : null,
                      child: Container(
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
                    ),
                    
                    // Message button (for viewing others' status) - direct to chat
                    if (!widget.isMyStatus)
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.white),
                        onPressed: () => _navigateToChat(),
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
  
  // Navigate to chat with the status owner
  void _navigateToChat() {
    Navigator.pushNamed(
      context,
      Constants.chatScreen,
      arguments: {
        Constants.contactUID: widget.status.uid,
        Constants.contactName: widget.status.userName,
        Constants.contactImage: widget.status.userImage,
        Constants.groupId: '',
      },
    );
  }
  
  // Show dialog with status viewers
  void _showViewersDialog() {
    if (!widget.isMyStatus) return;
    
    final currentItem = widget.status.items[_currentIndex];
    final viewerIds = currentItem.viewedBy;
    
    // Pause the timer
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Viewed by'),
        content: viewerIds.isEmpty
            ? const Text('No viewers yet')
            : SizedBox(
                width: double.maxFinite,
                height: 200,
                child: FutureBuilder(
                  future: _fetchViewerDetails(viewerIds),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final viewers = snapshot.data as List<Map<String, String>>;
                    
                    return ListView.builder(
                      itemCount: viewers.length,
                      itemBuilder: (context, index) {
                        final viewer = viewers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: viewer['image']!.isNotEmpty
                                ? CachedNetworkImageProvider(viewer['image']!)
                                : null,
                            child: viewer['image']!.isEmpty
                                ? Text(viewer['name']![0])
                                : null,
                          ),
                          title: Text(viewer['name']!),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Resume the timer
              setState(() {
                _isPaused = false;
              });
              _progressController.forward();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    ).then((_) {
      // Resume the timer if dialog is dismissed
      if (_isPaused) {
        setState(() {
          _isPaused = false;
        });
        _progressController.forward();
      }
    });
  }
  
  // Helper method to fetch details of status viewers
  Future<List<Map<String, String>>> _fetchViewerDetails(List<String> viewerIds) async {
    final List<Map<String, String>> viewers = [];
    
    // Filter out the current user's ID
    final currentUserId = context.read<AuthenticationProvider>().userModel!.uid;
    final otherViewerIds = viewerIds.where((id) => id != currentUserId).toList();
    
    // Fetch user details from Firestore
    final firestore = FirebaseFirestore.instance;
    
    for (final id in otherViewerIds) {
      try {
        final doc = await firestore.collection(Constants.users).doc(id).get();
        if (doc.exists) {
          viewers.add({
            'id': id,
            'name': doc.get(Constants.name) ?? 'Unknown',
            'image': doc.get(Constants.image) ?? '',
          });
        }
      } catch (e) {
        debugPrint('Error fetching viewer details: $e');
      }
    }
    
    return viewers;
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