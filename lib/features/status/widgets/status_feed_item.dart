import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/services/video_cache_service.dart';
import 'package:textgb/features/status/widgets/status_action_buttons.dart';
import 'package:textgb/features/status/widgets/status_progress_indicator.dart';
import 'package:textgb/features/status/widgets/status_user_info.dart';
import 'package:video_player/video_player.dart';

class StatusFeedItem extends StatefulWidget {
  final StatusModel status;
  final bool isCurrentUser;
  final int currentIndex;
  final int index;
  final bool isVisible;

  const StatusFeedItem({
    Key? key,
    required this.status,
    required this.isCurrentUser,
    required this.currentIndex,
    required this.index,
    this.isVisible = true,
  }) : super(key: key);

  @override
  State<StatusFeedItem> createState() => _StatusFeedItemState();
}

class _StatusFeedItemState extends State<StatusFeedItem> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  bool _isPlaying = true;
  bool _isMuted = false;
  double _progress = 0.0;
  bool _isCurrentlyActive = false;
  bool _isAppInForeground = true;
  bool _showHeartAnimation = false;
  bool _hasUserInteracted = false;
  bool _isVideoInitialized = false;
  
  // For multi-image statuses
  int _currentMediaIndex = 0;
  PageController? _mediaPageController;
  
  @override
  void initState() {
    super.initState();
    
    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Check if this is the current status
    _isCurrentlyActive = widget.currentIndex == widget.index;
    
    // Initialize current media index from status model
    _currentMediaIndex = widget.status.currentMediaIndex;
    
    // Initialize page controller for swiping between multiple media items
    if (widget.status.hasMultipleMedia) {
      _mediaPageController = PageController(initialPage: _currentMediaIndex);
    }
    
    // Initialize video controller if it's a video status, but DON'T autoplay by default
    if (widget.status.statusType == StatusType.video) {
      _initializeVideoController(autoPlayIfActive: false);
    }
    
    // Add a delay to check app start state after widgets are built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if this is a fresh app start
      if (mounted) {
        final isAppFreshStart = context.read<StatusProvider>().isAppFreshStart;
        
        if (isAppFreshStart) {
          // On fresh start, ensure videos are paused
          _ensureVideoStopped();
          
          // If this is the first status (index 0), mark app as no longer in fresh start
          if (widget.index == 0) {
            context.read<StatusProvider>().setAppFreshStart(false);
          }
        }
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      // Only play if this is the current status, app is in foreground, tab is visible,
      // AND user has interacted with the app since startup
      if (_isCurrentlyActive && 
          widget.isVisible && 
          widget.status.statusType == StatusType.video && 
          _hasUserInteracted &&
          _isVideoInitialized) {
        _playVideo();
      }
    } else {
      _isAppInForeground = false;
      // Pause video when app goes to background
      if (widget.status.statusType == StatusType.video) {
        _pauseVideo();
      }
    }
  }
  
  Future<void> _initializeVideoController({bool autoPlayIfActive = true}) async {
    final String videoUrl = widget.status.currentMediaUrl;
    
    if (videoUrl.isNotEmpty) {
      try {
        // Try to get cached video path
        final cacheService = VideoCacheService();
        String? videoPath = await cacheService.getCachedVideo(videoUrl);
        
        // If not cached, cache it now if user has interacted or this is the active status
        if (videoPath == null && (_hasUserInteracted || widget.currentIndex == widget.index)) {
          videoPath = await cacheService.cacheVideo(videoUrl);
        }
        
        // Initialize with cached file if available, otherwise use network URL
        if (videoPath != null) {
          _videoController = VideoPlayerController.file(
            File(videoPath),
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
            ),
          );
        } else {
          _videoController = VideoPlayerController.network(
            videoUrl,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
            ),
          );
        }
        
        // Set a timeout for initialization
        await _videoController!.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Video initialization timed out');
            throw Exception('Video initialization timed out');
          },
        );
        
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
        
        // Set up listeners for video progress
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _videoController!.value.isPlaying;
              
              if (_videoController!.value.duration.inMilliseconds > 0) {
                _progress = _videoController!.value.position.inMilliseconds /
                    _videoController!.value.duration.inMilliseconds;
              }
            });
          }
        });
        
        // Set initial volume (unmuted by default)
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
        
        // Auto-play only if specified and all conditions are met
        if (autoPlayIfActive && 
            _isCurrentlyActive && 
            _isAppInForeground && 
            widget.isVisible && 
            _hasUserInteracted && 
            !context.read<StatusProvider>().isAppFreshStart) {
          _playVideo();
        }
      } catch (e) {
        debugPrint('Error initializing video: $e');
      }
    }
  }
  
  void _playVideo() {
    if (_videoController != null && 
        _videoController!.value.isInitialized && 
        !_videoController!.value.isPlaying &&
        widget.isVisible && // Only play if tab is visible
        _isAppInForeground) {
      _videoController!.play();
      _videoController!.setLooping(true);
      setState(() {
        _isPlaying = true;
      });
    }
  }
  
  void _pauseVideo() {
    if (_videoController != null && 
        _videoController!.value.isInitialized && 
        _videoController!.value.isPlaying) {
      _videoController!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }
  
  void _togglePlayPause() {
    // When user manually toggles play/pause, track that they've interacted
    _hasUserInteracted = true;
    
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _pauseVideo();
      } else {
        _playVideo();
      }
    }
  }
  
  void _toggleMute() {
    // When user toggles mute, track that they've interacted
    _hasUserInteracted = true;
    
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        _isMuted = !_isMuted;
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }
  
  // Handle double-tap like animation
  void _handleDoubleTap() {
    // When user double-taps, track that they've interacted
    _hasUserInteracted = true;
    
    setState(() {
      _showHeartAnimation = true;
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }
  
  // Handle media navigation for multi-image statuses
  void _nextMedia() {
    if (!widget.status.hasMultipleMedia) return;
    
    final int mediaCount = widget.status.mediaUrls.length;
    if (_currentMediaIndex < mediaCount - 1) {
      final newIndex = _currentMediaIndex + 1;
      
      // Update index in provider
      context.read<StatusProvider>().updateStatusMediaIndex(widget.status.statusId, newIndex);
      
      // Update local state
      setState(() {
        _currentMediaIndex = newIndex;
      });
      
      // Animate to the next page
      _mediaPageController?.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Re-initialize video controller if needed
      if (widget.status.statusType == StatusType.video) {
        _isVideoInitialized = false;
        _videoController?.dispose();
        _videoController = null;
        _initializeVideoController(autoPlayIfActive: _hasUserInteracted);
      }
    }
  }
  
  // Handle media navigation for multi-image statuses
  void _previousMedia() {
    if (!widget.status.hasMultipleMedia) return;
    
    if (_currentMediaIndex > 0) {
      final newIndex = _currentMediaIndex - 1;
      
      // Update index in provider
      context.read<StatusProvider>().updateStatusMediaIndex(widget.status.statusId, newIndex);
      
      // Update local state
      setState(() {
        _currentMediaIndex = newIndex;
      });
      
      // Animate to the previous page
      _mediaPageController?.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Re-initialize video controller if needed
      if (widget.status.statusType == StatusType.video) {
        _isVideoInitialized = false;
        _videoController?.dispose();
        _videoController = null;
        _initializeVideoController(autoPlayIfActive: _hasUserInteracted);
      }
    }
  }
  
  // Handle page change in PageView
  void _onMediaPageChanged(int page) {
    if (_currentMediaIndex != page) {
      // Update index in provider
      context.read<StatusProvider>().updateStatusMediaIndex(widget.status.statusId, page);
      
      // Update local state
      setState(() {
        _currentMediaIndex = page;
      });
      
      // Re-initialize video controller if needed
      if (widget.status.statusType == StatusType.video) {
        _isVideoInitialized = false;
        _videoController?.dispose();
        _videoController = null;
        _initializeVideoController(autoPlayIfActive: _hasUserInteracted);
      }
    }
  }
  
  @override
  void didUpdateWidget(StatusFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the active status has changed
    final isNowActive = widget.currentIndex == widget.index;
    
    // When user swipes between statuses, track that they've interacted
    if (isNowActive != _isCurrentlyActive) {
      _hasUserInteracted = true;
    }
    
    // Only perform actions if the active state has changed
    if (isNowActive != _isCurrentlyActive) {
      _isCurrentlyActive = isNowActive;
      
      // Handle video playback when scrolling
      if (widget.status.statusType == StatusType.video) {
        if (_videoController != null && _videoController!.value.isInitialized) {
          if (isNowActive && _isAppInForeground && widget.isVisible) {
            // This is now the active status - play video only if tab is visible and user has interacted
            if (_hasUserInteracted && !context.read<StatusProvider>().isAppFreshStart) {
              _playVideo();
            }
            // Trigger appear animation
            _animationController.forward();
          } else {
            // This is no longer the active status - pause video
            _pauseVideo();
            // Trigger disappear animation
            _animationController.reverse();
          }
        } else if (isNowActive && !_isVideoInitialized) {
          // Video controller isn't initialized yet, try initializing now
          _initializeVideoController(autoPlayIfActive: _hasUserInteracted);
        }
      }
    }
    
    // Check if the status model has changed (e.g., currentMediaIndex was updated)
    if (widget.status.currentMediaIndex != oldWidget.status.currentMediaIndex) {
      _currentMediaIndex = widget.status.currentMediaIndex;
      
      // Update page controller
      if (_mediaPageController != null &&
          _mediaPageController!.hasClients &&
          _currentMediaIndex != _mediaPageController!.page?.round()) {
        _mediaPageController!.jumpToPage(_currentMediaIndex);
      }
      
      // Re-initialize video controller if needed
      if (widget.status.statusType == StatusType.video) {
        _isVideoInitialized = false;
        _videoController?.dispose();
        _videoController = null;
        _initializeVideoController(autoPlayIfActive: _hasUserInteracted && _isCurrentlyActive);
      }
    }
    
    // Check if visibility has changed
    if (widget.isVisible != oldWidget.isVisible) {
      if (!widget.isVisible) {
        // Tab has been hidden, pause video
        _pauseVideo();
      } else if (widget.isVisible && _isCurrentlyActive && _isAppInForeground) {
        // Tab has become visible and this is active status
        // Only play if user has interacted and it's not a fresh app start
        if (_hasUserInteracted && 
            !context.read<StatusProvider>().isAppFreshStart && 
            _isVideoInitialized) {
          _playVideo();
        }
      }
    }
  }
  
  // Ensure video is stopped in various scenarios
  void _ensureVideoStopped() {
    if (_videoController != null && 
        _videoController!.value.isInitialized && 
        _videoController!.value.isPlaying) {
      _pauseVideo();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if route is still active
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrentRoute) {
      // Not on current route, ensure video is stopped
      _ensureVideoStopped();
    }
  }
  
  @override
  void dispose() {
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Ensure video is stopped before disposing
    _ensureVideoStopped();
    
    // Dispose of the animation controller
    _animationController.dispose();
    
    // Dispose of the video controller
    if (_videoController != null) {
      _videoController!.removeListener(() {});
      _videoController!.dispose();
    }
    
    // Dispose of the page controller
    _mediaPageController?.dispose();
    
    super.dispose();
  }

  // Delete status function for current user
  void _deleteStatus() {
    // Mark user as interacting with the app
    _hasUserInteracted = true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: const Text('Are you sure you want to delete this status? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.read<StatusProvider>().deleteStatus(widget.status.statusId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Navigate to user profile
  void _goToUserProfile() {
    // Mark user as interacting with the app
    _hasUserInteracted = true;
    
    Navigator.pushNamed(
      context,
      Constants.profileScreen,
      arguments: widget.status.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: widget.status.statusType == StatusType.video 
            ? _togglePlayPause 
            : () {
                // Mark user as interacting even for non-video taps
                _hasUserInteracted = true;
              },
        onDoubleTap: _handleDoubleTap, // Add double-tap handler
        onLongPress: widget.isCurrentUser ? _deleteStatus : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Status content
            _buildStatusContent(),
            
            // Heart animation on double-tap
            if (_showHeartAnimation)
              Positioned.fill(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showHeartAnimation ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 120,
                    ),
                  ),
                ),
              ),
            
            // User info at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: StatusUserInfo(
                userName: widget.status.userName,
                userImage: widget.status.userImage,
                createdAt: widget.status.createdAt,
                onTap: _goToUserProfile,
              ),
            ),
            
            // Progress indicator for videos
            if (widget.status.statusType == StatusType.video && 
                _videoController != null && 
                _isVideoInitialized)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: StatusProgressIndicator(progress: _progress),
              ),
            
            // Multiple media indicator for images/videos (dots at bottom)
            if (widget.status.hasMultipleMedia)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 0,
                right: 0,
                child: _buildMediaIndicator(),
              ),
            
            // Navigation arrows for multiple media
            if (widget.status.hasMultipleMedia)
              Row(
                children: [
                  // Left arrow for previous media
                  if (_currentMediaIndex > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _previousMedia,
                        child: Container(
                          height: double.infinity,
                          width: MediaQuery.of(context).size.width * 0.2,
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  Spacer(),
                  
                  // Right arrow for next media
                  if (_currentMediaIndex < widget.status.mediaUrls.length - 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _nextMedia,
                        child: Container(
                          height: double.infinity,
                          width: MediaQuery.of(context).size.width * 0.2,
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            
            // Enhanced caption with background
            if (widget.status.caption.isNotEmpty)
              Positioned(
                left: 16,
                right: 80, // Make room for action buttons
                bottom: 60, // Moved up a bit for better visibility
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3), // Semi-transparent background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.status.caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.3, // Better line height
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            
            // Action buttons (right side)
            Positioned(
              right: 16,
              bottom: 100,
              child: StatusActionButtons(
                status: widget.status,
                isCurrentUser: widget.isCurrentUser,
                isMuted: _isMuted,
                onMuteToggle: widget.status.statusType == StatusType.video 
                    ? _toggleMute 
                    : null,
                onDelete: widget.isCurrentUser ? _deleteStatus : null,
              ),
            ),
            
            // "Swipe up for next" indicator
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _isCurrentlyActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Swipe up for next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build media indicator dots for multiple images/videos
  Widget _buildMediaIndicator() {
    if (!widget.status.hasMultipleMedia) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.status.mediaUrls.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentMediaIndex
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusContent() {
    // For text status, just use the text background
    if (widget.status.statusType == StatusType.text) {
      // Parse hex color codes
      Color bgColor = _parseColor(widget.status.backgroundColor);
      Color textColor = _parseColor(widget.status.textColor);
      
      return Container(
        color: bgColor,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            widget.status.caption,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.4,
              fontFamily: widget.status.fontStyle == 'normal'
                  ? null
                  : widget.status.fontStyle,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // For media content
    if (widget.status.hasMultipleMedia) {
      // Use PageView for multiple media
      return PageView.builder(
        controller: _mediaPageController,
        onPageChanged: _onMediaPageChanged,
        itemCount: widget.status.mediaUrls.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final mediaUrl = widget.status.mediaUrls[index];
          
          if (widget.status.statusType == StatusType.image) {
            return CachedNetworkImage(
              imageUrl: mediaUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: Colors.white),
              ),
            );
          } else if (widget.status.statusType == StatusType.video && 
                    index == _currentMediaIndex &&
                    _videoController != null &&
                    _isVideoInitialized) {
            return FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
        },
      );
    } else {
      // Single media display
      if (widget.status.statusType == StatusType.image) {
        return CachedNetworkImage(
          imageUrl: widget.status.currentMediaUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error, color: Colors.white),
          ),
        );
      } else if (widget.status.statusType == StatusType.video && 
                 _videoController != null && 
                 _isVideoInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
    }
  }
  
  // Helper function to parse hex color
  Color _parseColor(String hexCode) {
    try {
      hexCode = hexCode.replaceAll('#', '');
      if (hexCode.length == 6) {
        hexCode = 'FF$hexCode';
      }
      return Color(int.parse(hexCode, radix: 16));
    } catch (e) {
      return hexCode.toLowerCase() == '#ffffff' ? Colors.white : Colors.black;
    }
  }
}