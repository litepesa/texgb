// lib/features/status/screens/status_viewer_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class StatusViewerScreen extends ConsumerStatefulWidget {
  final UserStatusGroup statusGroup;
  final int initialIndex;
  final String currentUserId;

  const StatusViewerScreen({
    super.key,
    required this.statusGroup,
    required this.currentUserId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  Timer? _progressTimer;
  
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isLoading = true;
  Duration _statusDuration = const Duration(seconds: 5);

  // Video specific controllers
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoInitialized = {};
  
  // Caption expansion state
  final Map<int, bool> _captionExpanded = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCurrentStatus();
      _markCurrentStatusAsViewed();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _progressTimer?.cancel();
    _disposeVideoControllers();
    super.dispose();
  }

  void _disposeVideoControllers() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
  }

  Future<void> _initializeCurrentStatus() async {
    final currentStatus = widget.statusGroup.statuses[_currentIndex];
    
    setState(() => _isLoading = true);
    
    if (currentStatus.type == StatusType.video) {
      await _initializeVideoForStatus(_currentIndex);
    }
    
    setState(() => _isLoading = false);
    _startStatusTimer();
  }

  Future<void> _initializeVideoForStatus(int index) async {
    if (_videoControllers.containsKey(index)) return;
    
    final status = widget.statusGroup.statuses[index];
    if (status.type != StatusType.video) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(status.content));
      await controller.initialize();
      
      _videoControllers[index] = controller;
      _videoInitialized[index] = true;
      
      // Set video duration as status duration
      _statusDuration = controller.value.duration;
      
      // Add listener for progress tracking
      controller.addListener(() => _videoProgressListener(index));
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing video for status $index: $e');
      _videoInitialized[index] = false;
    }
  }

  void _videoProgressListener(int index) {
    final controller = _videoControllers[index];
    if (controller == null || index != _currentIndex || !mounted) return;

    final position = controller.value.position;
    final duration = controller.value.duration;

    // Update progress based on video position
    if (duration != Duration.zero) {
      final progress = position.inMilliseconds / duration.inMilliseconds;
      _progressController.value = progress.clamp(0.0, 1.0);
    }

    // Check if video ended
    if (position >= duration && duration != Duration.zero) {
      _nextStatus();
    }
  }

  void _startStatusTimer() {
    _progressTimer?.cancel();
    _progressController.reset();
    
    final currentStatus = widget.statusGroup.statuses[_currentIndex];
    
    if (currentStatus.type == StatusType.video) {
      // For videos, let the video control the progress
      final controller = _videoControllers[_currentIndex];
      if (controller != null && _videoInitialized[_currentIndex] == true) {
        if (!_isPaused) {
          controller.play();
        }
        return;
      }
    }
    
    // For non-video statuses, use timer-based progress
    _progressController.duration = _statusDuration;
    if (!_isPaused) {
      _progressController.forward();
      
      _progressTimer = Timer(_statusDuration, () {
        if (mounted && !_isPaused) {
          _nextStatus();
        }
      });
    }
  }

  void _pauseStatus() {
    setState(() => _isPaused = true);
    
    final currentStatus = widget.statusGroup.statuses[_currentIndex];
    if (currentStatus.type == StatusType.video) {
      final controller = _videoControllers[_currentIndex];
      controller?.pause();
    } else {
      _progressController.stop();
      _progressTimer?.cancel();
    }
  }

  void _resumeStatus() {
    setState(() => _isPaused = false);
    
    final currentStatus = widget.statusGroup.statuses[_currentIndex];
    if (currentStatus.type == StatusType.video) {
      final controller = _videoControllers[_currentIndex];
      controller?.play();
    } else {
      _progressController.forward();
      
      final remainingTime = Duration(
        milliseconds: ((1 - _progressController.value) * _statusDuration.inMilliseconds).round(),
      );
      
      _progressTimer = Timer(remainingTime, () {
        if (mounted && !_isPaused) {
          _nextStatus();
        }
      });
    }
  }

  void _nextStatus() {
    if (_currentIndex < widget.statusGroup.statuses.length - 1) {
      // Pause current video
      final currentController = _videoControllers[_currentIndex];
      currentController?.pause();
      
      setState(() => _currentIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _initializeCurrentStatus();
      _markCurrentStatusAsViewed();
    } else {
      // End of current user's statuses - navigate to next user or back to status screen
      _handleStatusGroupComplete();
    }
  }

  void _handleStatusGroupComplete() async {
    // Prevent multiple navigation calls
    if (!mounted) return;
    
    try {
      // Get all status groups from the provider
      final statusGroups = await ref.read(statusStreamProvider.future);
      
      if (!mounted) return;
      
      // Find current user's index in the groups
      int currentGroupIndex = -1;
      for (int i = 0; i < statusGroups.length; i++) {
        if (statusGroups[i].userId == widget.statusGroup.userId) {
          currentGroupIndex = i;
          break;
        }
      }
      
      // Look for next user with unviewed statuses
      UserStatusGroup? nextGroup;
      for (int i = currentGroupIndex + 1; i < statusGroups.length; i++) {
        final group = statusGroups[i];
        if (!group.isMyStatus && group.hasUnviewedStatuses(widget.currentUserId)) {
          nextGroup = group;
          break;
        }
      }
      
      if (nextGroup != null && mounted) {
        // Navigate to next user's status
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => StatusViewerScreen(
              statusGroup: nextGroup!,
              currentUserId: widget.currentUserId,
              initialIndex: 0,
            ),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          ),
        );
      } else if (mounted) {
        // No more unviewed statuses - go back to status screen
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error handling status group completion: $e');
      // Fallback: just go back to status screen
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _previousStatus() {
    if (_currentIndex > 0) {
      // Pause current video
      final currentController = _videoControllers[_currentIndex];
      currentController?.pause();
      
      setState(() => _currentIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _initializeCurrentStatus();
      _markCurrentStatusAsViewed();
    }
  }

  void _markCurrentStatusAsViewed() {
    if (_currentIndex < widget.statusGroup.statuses.length) {
      final status = widget.statusGroup.statuses[_currentIndex];
      if (!status.hasUserViewed(widget.currentUserId)) {
        ref.read(statusNotifierProvider.notifier).markStatusAsViewed(
          statusId: status.statusId,
          viewerId: widget.currentUserId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          // Prevent interaction during navigation
          if (!mounted) return;
          _pauseStatus();
        },
        onTapUp: (details) {
          // Prevent interaction during navigation
          if (!mounted) return;
          
          _resumeStatus();
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < screenWidth * 0.3) {
            _previousStatus();
          } else if (details.localPosition.dx > screenWidth * 0.7) {
            _nextStatus();
          }
        },
        onTapCancel: () {
          if (mounted) _resumeStatus();
        },
        child: Stack(
          children: [
            // Status content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                // Pause previous video
                final prevController = _videoControllers[_currentIndex];
                prevController?.pause();
                
                setState(() => _currentIndex = index);
                _initializeCurrentStatus();
                _markCurrentStatusAsViewed();
              },
              itemCount: widget.statusGroup.statuses.length,
              itemBuilder: (context, index) {
                return _buildStatusContent(widget.statusGroup.statuses[index], index);
              },
            ),
            
            // Top overlay with progress and user info
            _buildTopOverlay(theme),
            
            // Bottom overlay with actions (if own status)
            if (widget.statusGroup.isMyStatus) _buildBottomOverlay(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusModel status, int index) {
    switch (status.type) {
      case StatusType.text:
        return _buildTextStatus(status);
      case StatusType.image:
        return _buildImageStatus(status, index);
      case StatusType.video:
        return _buildVideoStatus(status, index);
      default:
        return _buildTextStatus(status);
    }
  }

  Widget _buildTextStatus(StatusModel status) {
    Color backgroundColor = Colors.black;
    Color textColor = Colors.white;
    
    if (status.backgroundColor != null) {
      backgroundColor = Color(
        int.parse(status.backgroundColor!.substring(1, 7), radix: 16) + 0xFF000000,
      );
    }
    
    if (status.fontColor != null) {
      textColor = Color(
        int.parse(status.fontColor!.substring(1, 7), radix: 16) + 0xFF000000,
      );
    }
    
    return Container(
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            status.content,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontFamily: status.fontFamily == 'default' ? null : status.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildImageStatus(StatusModel status, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: status.content,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error, color: Colors.white),
          ),
        ),
        
        // Caption overlay - expandable style
        if (status.caption != null && status.caption!.isNotEmpty)
          _buildExpandableCaption(status.caption!, index),
      ],
    );
  }

  Widget _buildVideoStatus(StatusModel status, int index) {
    final controller = _videoControllers[index];
    final isInitialized = _videoInitialized[index] == true;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        if (isInitialized && controller != null)
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        
        // Play/pause overlay - floating/transparent style
        if (!_isLoading && (!isInitialized || _isPaused))
          Center(
            child: Icon(
              Icons.play_arrow,
              color: Colors.white.withOpacity(0.8),
              size: 80,
              shadows: const [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 8,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        
        // Caption overlay - expandable style
        if (status.caption != null && status.caption!.isNotEmpty)
          _buildExpandableCaption(status.caption!, index),
      ],
    );
  }

  Widget _buildExpandableCaption(String caption, int statusIndex) {
    // Check if caption needs truncation (more than 2 lines estimated)
    final isLongCaption = caption.length > 100 || caption.split('\n').length > 2;
    final isExpanded = _captionExpanded[statusIndex] ?? false;
    
    // Create truncated version
    String displayText = caption;
    if (isLongCaption && !isExpanded) {
      // Split by lines first
      final lines = caption.split('\n');
      if (lines.length > 2) {
        displayText = lines.take(2).join('\n');
        // If the second line is too long, truncate it
        final secondLineWords = displayText.split(' ');
        if (secondLineWords.length > 15) {
          displayText = secondLineWords.take(15).join(' ');
        }
      } else {
        // Single long line - truncate by words
        final words = caption.split(' ');
        if (words.length > 15) {
          displayText = words.take(15).join(' ');
        }
      }
    }
    
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          if (isLongCaption) {
            setState(() {
              _captionExpanded[statusIndex] = !isExpanded;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
                height: 1.3,
              ),
              children: [
                TextSpan(text: displayText),
                if (isLongCaption) ...[
                  if (!isExpanded) ...[
                    const TextSpan(text: '... '),
                    TextSpan(
                      text: 'more',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ] else ...[
                    if (displayText != caption)
                      TextSpan(
                        text: caption.substring(displayText.length),
                      ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: 'less',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay(ModernThemeExtension theme) {
    return SafeArea(
      child: Column(
        children: [
          // Progress indicators
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                widget.statusGroup.statuses.length,
                (index) => Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(
                      right: index < widget.statusGroup.statuses.length - 1 ? 4 : 0,
                    ),
                    child: LinearProgressIndicator(
                      value: index < _currentIndex
                          ? 1.0
                          : index == _currentIndex
                              ? _progressController.value
                              : 0.0,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // User info and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Profile picture
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
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                          )
                        : Container(
                            color: Colors.grey,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // User name and time
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
                      if (_currentIndex < widget.statusGroup.statuses.length)
                        Text(
                          _getStatusTimeText(widget.statusGroup.statuses[_currentIndex]),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Mute button for videos
                if (_currentIndex < widget.statusGroup.statuses.length &&
                    widget.statusGroup.statuses[_currentIndex].type == StatusType.video &&
                    _videoControllers[_currentIndex] != null)
                  GestureDetector(
                    onTap: () {
                      final controller = _videoControllers[_currentIndex];
                      if (controller != null) {
                        final currentVolume = controller.value.volume;
                        controller.setVolume(currentVolume > 0 ? 0.0 : 1.0);
                        setState(() {});
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _videoControllers[_currentIndex]?.value.volume == 0
                            ? Icons.volume_off
                            : Icons.volume_up,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                
                const SizedBox(width: 8),
                
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay(ModernThemeExtension theme) {
    if (_currentIndex >= widget.statusGroup.statuses.length) return const SizedBox();
    
    final currentStatus = widget.statusGroup.statuses[_currentIndex];
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // View count
              GestureDetector(
                onTap: () => _showViewers(currentStatus),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${currentStatus.viewCount}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Delete button
              GestureDetector(
                onTap: () => _deleteStatus(currentStatus),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusTimeText(StatusModel status) {
    final now = DateTime.now();
    final difference = now.difference(status.createdAt);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showViewers(StatusModel status) async {
    final viewers = await ref.read(statusNotifierProvider.notifier).getStatusViewers(status.statusId);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = context.modernTheme;
        return Container(
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Viewed by ${viewers.length}',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (viewers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No views yet',
                    style: TextStyle(color: theme.textSecondaryColor),
                  ),
                )
              else
                ...viewers.map((viewer) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: viewer.image.isNotEmpty
                        ? CachedNetworkImageProvider(viewer.image)
                        : null,
                    child: viewer.image.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    viewer.name,
                    style: TextStyle(color: theme.textColor),
                  ),
                )).toList(),
            ],
          ),
        );
      },
    );
  }

  void _deleteStatus(StatusModel status) {
    showMyAnimatedDialog(
      context: context,
      title: 'Delete Status',
      content: 'Are you sure you want to delete this status?',
      textAction: 'Delete',
      onActionTap: (confirmed) async {
        if (confirmed && mounted) {
          try {
            await ref.read(statusNotifierProvider.notifier).deleteStatus(status.statusId);
            
            if (!mounted) return;
            
            // If this was the only status, go back
            if (widget.statusGroup.statuses.length <= 1) {
              Navigator.pop(context);
              return;
            }
            
            // If this was the last status in the group, move to previous or handle completion
            if (_currentIndex >= widget.statusGroup.statuses.length - 1) {
              if (_currentIndex > 0) {
                // Move to previous status
                setState(() => _currentIndex--);
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _initializeCurrentStatus();
                _markCurrentStatusAsViewed();
              } else {
                // This was the first and last status, handle completion
                _handleStatusGroupComplete();
              }
            } else {
              // Move to next status (same index since current was deleted)
              _initializeCurrentStatus();
              _markCurrentStatusAsViewed();
            }
          } catch (e) {
            debugPrint('Error deleting status: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete status')),
              );
            }
          }
        }
      },
    );
  }
}