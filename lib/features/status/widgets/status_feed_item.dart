import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/status_action_buttons.dart';
import 'package:textgb/features/status/widgets/status_progress_indicator.dart';
import 'package:textgb/features/status/widgets/status_user_info.dart';
import 'package:textgb/models/status_model.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/widgets/video_player_widget.dart';

class StatusFeedItem extends StatefulWidget {
  final StatusModel status;
  final bool isCurrentUser;
  final int currentIndex;
  final int index;

  const StatusFeedItem({
    Key? key,
    required this.status,
    required this.isCurrentUser,
    required this.currentIndex,
    required this.index,
  }) : super(key: key);

  @override
  State<StatusFeedItem> createState() => _StatusFeedItemState();
}

class _StatusFeedItemState extends State<StatusFeedItem> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isMuted = true;
  double _progress = 0.0;
  bool _isCurrentlyActive = false;
  bool _isAppInForeground = true;
  
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
    
    // Initialize video controller if it's a video status
    if (widget.status.statusType == StatusType.video) {
      _initializeVideoController();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      // Only play if this is the current status and app is in foreground
      if (_isCurrentlyActive && widget.status.statusType == StatusType.video) {
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
  
  Future<void> _initializeVideoController() async {
    if (widget.status.statusUrl.isNotEmpty) {
      _videoController = VideoPlayerController.network(widget.status.statusUrl);
      
      // Add try-catch to handle network errors
      try {
        await _videoController!.initialize();
        
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
        
        // Set initial mute state
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
        
        // Auto-play when this status becomes active and app is in foreground
        if (_isCurrentlyActive && _isAppInForeground) {
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
        !_videoController!.value.isPlaying) {
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
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _pauseVideo();
      } else {
        _playVideo();
      }
    }
  }
  
  void _toggleMute() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        _isMuted = !_isMuted;
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }
  
  @override
  void didUpdateWidget(StatusFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the active status has changed
    final isNowActive = widget.currentIndex == widget.index;
    
    // Only perform actions if the active state has changed
    if (isNowActive != _isCurrentlyActive) {
      _isCurrentlyActive = isNowActive;
      
      // Handle video playback when scrolling
      if (widget.status.statusType == StatusType.video && _videoController != null) {
        if (isNowActive && _isAppInForeground) {
          // This is now the active status - play video
          _playVideo();
          // Trigger appear animation
          _animationController.forward();
        } else {
          // This is no longer the active status - pause video
          _pauseVideo();
          // Trigger disappear animation
          _animationController.reverse();
        }
      }
    }
  }
  
  @override
  void dispose() {
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Dispose of the animation controller
    _animationController.dispose();
    
    // Properly dispose of the video controller
    if (_videoController != null) {
      _videoController!.removeListener(() {});
      _videoController!.dispose();
    }
    
    super.dispose();
  }

  // Delete status function for current user
  void _deleteStatus() {
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
            : null,
        onLongPress: widget.isCurrentUser ? _deleteStatus : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Status content
            _buildStatusContent(),
            
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
            
            // Progress indicator
            if (widget.status.statusType == StatusType.video && 
                _videoController != null && 
                _videoController!.value.isInitialized)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: StatusProgressIndicator(progress: _progress),
              ),
            
            // Caption
            if (widget.status.caption.isNotEmpty)
              Positioned(
                left: 16,
                right: 80, // Make room for action buttons
                bottom: 50,
                child: Text(
                  widget.status.caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
              child: Center(
                child: Column(
                  children: const [
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Swipe up for next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusContent() {
    switch (widget.status.statusType) {
      case StatusType.image:
        return CachedNetworkImage(
          imageUrl: widget.status.statusUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error, color: Colors.white),
          ),
        );
        
      case StatusType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
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
        
      case StatusType.text:
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
        
      default:
        return const Center(
          child: Text('Unsupported status type', style: TextStyle(color: Colors.white)),
        );
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