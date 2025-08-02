// lib/features/status/screens/status_viewer_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/utilities/time_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';


class StatusViewerScreen extends ConsumerStatefulWidget {
  final UserStatusGroup statusGroup;
  final int initialIndex;

  const StatusViewerScreen({
    super.key,
    required this.statusGroup,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late List<StatusModel> _statuses;
  
  int _currentIndex = 0;
  Timer? _progressTimer;
  Timer? _autoAdvanceTimer;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPaused = false;
  bool _showUI = true;
  Timer? _hideUITimer;

  // Progress animation duration for each status type
  static const Duration _textStatusDuration = Duration(seconds: 5);
  static const Duration _imageStatusDuration = Duration(seconds: 3);
  static const Duration _videoStatusDuration = Duration(seconds: 15); // Max duration

  @override
  void initState() {
    super.initState();
    _statuses = widget.statusGroup.activeStatuses;
    _currentIndex = widget.initialIndex.clamp(0, _statuses.length - 1);
    
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      duration: _getStatusDuration(_statuses[_currentIndex]),
      vsync: this,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCurrentStatus();
    });
    
    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _hideUITimer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    _videoController?.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Duration _getStatusDuration(StatusModel status) {
    switch (status.statusType) {
      case Constants.statusTypeText:
        return _textStatusDuration;
      case Constants.statusTypeImage:
        return _imageStatusDuration;
      case Constants.statusTypeVideo:
        return _videoStatusDuration;
      default:
        return _imageStatusDuration;
    }
  }

  void _initializeCurrentStatus() {
    final status = _statuses[_currentIndex];
    
    // Mark status as viewed
    ref.read(statusNotifierProvider.notifier).viewStatus(status);
    
    // Initialize video if needed
    if (status.isVideoStatus && status.statusMediaUrl != null) {
      _initializeVideo(status.statusMediaUrl!);
    } else {
      _startProgress();
    }
    
    // Start UI hide timer
    _startUIHideTimer();
  }

  void _initializeVideo(String videoUrl) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    
    try {
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      
      _videoController!.play();
      _startProgress();
      
      // Listen for video completion
      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _nextStatus();
        }
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
      setState(() {
        _isVideoInitialized = false;
      });
      _startProgress();
    }
  }

  void _startProgress() {
    _progressController.reset();
    
    final duration = _getStatusDuration(_statuses[_currentIndex]);
    _progressController.duration = duration;
    
    if (!_isPaused) {
      _progressController.forward();
      
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(duration, () {
        if (mounted && !_isPaused) {
          _nextStatus();
        }
      });
    }
  }

  void _pauseProgress() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    _autoAdvanceTimer?.cancel();
    _videoController?.pause();
  }

  void _resumeProgress() {
    setState(() {
      _isPaused = false;
    });
    
    if (_progressController.isAnimating) {
      _progressController.forward();
    } else {
      _startProgress();
    }
    
    _videoController?.play();
  }

  void _nextStatus() {
    if (_currentIndex < _statuses.length - 1) {
      _currentIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Move to next user's status or close
      Navigator.pop(context);
    }
  }

  void _previousStatus() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _onPageChanged(int index) {
    _currentIndex = index;
    _progressController.reset();
    _autoAdvanceTimer?.cancel();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    
    setState(() {});
    
    _initializeCurrentStatus();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    
    if (_showUI) {
      _startUIHideTimer();
    } else {
      _hideUITimer?.cancel();
    }
  }

  void _startUIHideTimer() {
    _hideUITimer?.cancel();
    _hideUITimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showUI = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUI,
        onLongPressStart: (_) => _pauseProgress(),
        onLongPressEnd: (_) => _resumeProgress(),
        child: Stack(
          children: [
            // Status content
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                return _buildStatusContent(_statuses[index]);
              },
            ),
            
            // Progress indicators
            if (_showUI) _buildProgressIndicators(),
            
            // Top overlay with user info and close button
            if (_showUI) _buildTopOverlay(),
            
            // Bottom overlay with reply button
            if (_showUI) _buildBottomOverlay(),
            
            // Navigation areas (invisible tap zones)
            _buildNavigationAreas(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusModel status) {
    switch (status.statusType) {
      case Constants.statusTypeText:
        return _buildTextStatus(status);
      case Constants.statusTypeImage:
        return _buildImageStatus(status);
      case Constants.statusTypeVideo:
        return _buildVideoStatus(status);
      default:
        return _buildTextStatus(status);
    }
  }

  Widget _buildTextStatus(StatusModel status) {
    final backgroundColor = status.statusBackgroundColor != null
        ? Color(int.parse(status.statusBackgroundColor!))
        : Colors.blue;
    
    final textColor = status.statusTextColor != null
        ? Color(int.parse(status.statusTextColor!))
        : Colors.white;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            status.statusContent,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontFamily: status.statusFont,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildImageStatus(StatusModel status) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CachedNetworkImage(
        imageUrl: status.statusMediaUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoStatus(StatusModel status) {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: status.statusThumbnail != null
              ? Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: status.statusThumbnail!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ],
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildProgressIndicators() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(_statuses.length, (index) {
          return Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.only(right: index < _statuses.length - 1 ? 4 : 0),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  double progress = 0.0;
                  
                  if (index < _currentIndex) {
                    progress = 1.0;
                  } else if (index == _currentIndex) {
                    progress = _progressController.value;
                  }
                  
                  return LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopOverlay() {
    final status = _statuses[_currentIndex];
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // User profile
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: widget.statusGroup.userImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.statusGroup.userImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey,
                        child: Center(
                          child: Text(
                            widget.statusGroup.userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey,
                      child: Center(
                        child: Text(
                          widget.statusGroup.userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.statusGroup.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  TimeUtils.getStatusTimeAgo(status.statusCreatedAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // More options
          IconButton(
            onPressed: _showStatusOptions,
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
          
          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Reply input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Reply to ${widget.statusGroup.userName}...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _sendReply,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Heart reaction
          GestureDetector(
            onTap: _sendHeartReaction,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationAreas() {
    return Row(
      children: [
        // Left tap area (previous)
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: _previousStatus,
            child: Container(
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
        ),
        
        // Center tap area (pause/play)
        Expanded(
          flex: 2,
          child: Container(
            height: double.infinity,
            color: Colors.transparent,
          ),
        ),
        
        // Right tap area (next)
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: _nextStatus,
            child: Container(
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  void _showStatusOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  _reportStatus();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block'),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendReply(String reply) {
    if (reply.trim().isEmpty) return;
    
    // TODO: Implement status reply functionality
    debugPrint('Sending reply: $reply');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reply sent'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _sendHeartReaction() {
    // TODO: Implement heart reaction functionality
    debugPrint('Sending heart reaction');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❤️ Reaction sent'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _reportStatus() {
    // TODO: Implement report functionality
    debugPrint('Reporting status');
  }

  void _blockUser() {
    // TODO: Implement block user functionality
    debugPrint('Blocking user');
  }
}