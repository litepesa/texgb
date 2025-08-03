// lib/features/status/screens/status_viewer_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/video_status_widget.dart';
import 'package:textgb/features/status/widgets/status_thumbnail_widget.dart';
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
  Duration _currentStatusElapsed = Duration.zero;

  // Video specific controllers
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoInitialized = {};

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
    
    if (currentStatus.type == StatusType.video) {
      await _initializeVideoForStatus(_currentIndex);
    }
    
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
      
      if (mounted) {
        setState(() {});
      }
      
      // Auto-play video when initialized
      if (index == _currentIndex && !_isPaused) {
        controller.play();
        controller.addListener(() => _videoListener(index));
      }
    } catch (e) {
      debugPrint('Error initializing video for status $index: $e');
      _videoInitialized[index] = false;
    }
  }

  void _videoListener(int index) {
    final controller = _videoControllers[index];
    if (controller == null || index != _currentIndex) return;

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
        controller.play();
        return;
      }
    }
    
    // For non-video statuses, use timer
    _progressController.duration = _statusDuration;
    _progressController.forward();
    
    _progressTimer = Timer(_statusDuration, () {
      if (mounted && !_isPaused) {
        _nextStatus();
      }
    });
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
      Navigator.pop(context);
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
        onTapDown: (details) => _pauseStatus(),
        onTapUp: (details) {
          _resumeStatus();
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < screenWidth * 0.3) {
            _previousStatus();
          } else if (details.localPosition.dx > screenWidth * 0.7) {
            _nextStatus();
          }
        },
        onTapCancel: () => _resumeStatus(),
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
        return _buildImageStatus(status);
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

  Widget _buildImageStatus(StatusModel status) {
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
        
        // Caption overlay
        if (status.caption != null && status.caption!.isNotEmpty)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.caption!,
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

  Widget _buildVideoStatus(StatusModel status, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player widget
        VideoStatusWidget(
          videoUrl: status.content,
          caption: status.caption,
          autoPlay: index == _currentIndex && !_isPaused,
          showControls: false, // We handle controls in the overlay
          onProgress: (duration) {
            // Update progress based on video playback
            final controller = _videoControllers[index];
            if (controller != null && controller.value.duration != Duration.zero) {
              final progress = duration.inMilliseconds / controller.value.duration.inMilliseconds;
              _progressController.value = progress.clamp(0.0, 1.0);
            }
          },
          onVideoEnd: () {
            _nextStatus();
          },
        ),
        
        // Video controls overlay (tap to play/pause)
        if (_videoInitialized[index] == true)
          GestureDetector(
            onTap: () {
              final controller = _videoControllers[index];
              if (controller != null) {
                if (controller.value.isPlaying) {
                  _pauseStatus();
                } else {
                  _resumeStatus();
                }
              }
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
      ],
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
                    height: 2,
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
                    widget.statusGroup.statuses[_currentIndex].type == StatusType.video)
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
        if (confirmed) {
          await ref.read(statusNotifierProvider.notifier).deleteStatus(status.statusId);
          if (mounted) {
            // If this was the only status, close viewer
            if (widget.statusGroup.statuses.length == 1) {
              Navigator.pop(context);
            } else {
              // Move to next status or close if this was the last
              if (_currentIndex >= widget.statusGroup.statuses.length - 1) {
                Navigator.pop(context);
              } else {
                _nextStatus();
              }
            }
          }
        }
      },
    );
  }
}